"""Airflow DAGs for this repo's dbt project, built with Cosmos: one DAG per layer.

Lineage (each arrow is an Airflow Asset: the upstream DAG updates it when all its
tasks succeed, and the downstream DAG is scheduled on it):

    dwh_seeds ──> dwh_staging ──┬──> dwh_snapshots ────┬──> dwh_core ──┬──> dwh_finance
                                └──> dwh_intermediate ─┘                └──> dwh_product

- dwh_seeds:        loads the raw data (seeds). Start it by hand.
- dwh_staging:      staging models (models/staging)
- dwh_snapshots:    SCD2 snapshots of the staging models (snapshots/)
- dwh_intermediate: intermediate models (models/intermediate)
- dwh_core:         core dimensions and facts (models/marts/core). Starts only when
                    BOTH dwh_snapshots and dwh_intermediate have finished.
- dwh_finance:      Finance domain marts (models/marts/finance)
- dwh_product:      Product domain marts (models/marts/product)

Each dbt model runs with its tests right after it (Cosmos default).

Cosmos reads the dbt project from target/manifest.json (fast: no dbt command when
Airflow loads this file). airflow.sh runs `dbt parse` first, so the manifest is
always up to date.
"""

from datetime import datetime
from pathlib import Path

from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.sdk import DAG, Asset
from cosmos import DbtTaskGroup, ExecutionConfig, LoadMode, ProfileConfig, ProjectConfig, RenderConfig

REPO_DIR = Path(__file__).resolve().parent.parent

# DuckDB allows only one writer at a time. All dbt tasks of all DAGs use this pool,
# which has 1 slot, so they never write at the same time. Create it once with:
#   ./airflow.sh pools set duckdb_writer 1 "One dbt task at a time (DuckDB)"
DBT_POOL = "duckdb_writer"

# Assets that link the DAGs (see the lineage above).
SEEDS_LOADED = Asset("dwh://seeds_loaded")
STAGING_BUILT = Asset("dwh://staging_built")
SNAPSHOTS_BUILT = Asset("dwh://snapshots_built")
INTERMEDIATE_BUILT = Asset("dwh://intermediate_built")
CORE_BUILT = Asset("dwh://core_built")

project_config = ProjectConfig(
    dbt_project_path=REPO_DIR,
    manifest_path=REPO_DIR / "target" / "manifest.json",
    # Packages (Elementary) are already installed in dbt_packages/; do not run
    # `dbt deps` for every task.
    install_dbt_deps=False,
    # Cosmos runs dbt from a temporary copy of the project, so give dbt
    # the full path to the DuckDB file in the repo.
    env_vars={"DBT_DUCKDB_PATH": str(REPO_DIR / "dwh.duckdb")},
)
profile_config = ProfileConfig(
    profile_name="dwh",
    target_name="prod",
    profiles_yml_filepath=REPO_DIR / "profiles.yml",
)
execution_config = ExecutionConfig(
    dbt_executable_path=str(REPO_DIR / ".venv" / "bin" / "dbt"),
)

common_dag_args = dict(
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
)


def dbt_layer_dag(dag_id, select, schedule, outlet=None, detach_multi_model_tests=False):
    """One DAG that runs the dbt resources in `select`, then updates `outlet`."""
    with DAG(dag_id=dag_id, schedule=schedule, **common_dag_args) as dag:
        layer = DbtTaskGroup(
            group_id="dbt",
            project_config=project_config,
            profile_config=profile_config,
            execution_config=execution_config,
            render_config=RenderConfig(
                load_method=LoadMode.DBT_MANIFEST,
                select=select,
                # Tests that read more than 1 model run as their own task after those
                # models. Only used in dwh_core, where all of their models are built.
                should_detach_multiple_parents_tests=detach_multi_model_tests,
            ),
            operator_args={"pool": DBT_POOL},
        )
        if outlet is not None:
            # Runs only if every dbt task succeeded; this starts the next DAG(s).
            done = EmptyOperator(task_id="layer_done", outlets=[outlet])
            layer >> done
    return dag


# Start by hand: loads the raw data.
dbt_layer_dag("dwh_seeds", ["resource_type:seed"], schedule=None, outlet=SEEDS_LOADED)

# After the seeds.
dbt_layer_dag("dwh_staging", ["path:models/staging"], schedule=[SEEDS_LOADED], outlet=STAGING_BUILT)

# After staging. These 2 DAGs start at the same time.
dbt_layer_dag("dwh_snapshots", ["resource_type:snapshot"], schedule=[STAGING_BUILT], outlet=SNAPSHOTS_BUILT)
dbt_layer_dag("dwh_intermediate", ["path:models/intermediate"], schedule=[STAGING_BUILT], outlet=INTERMEDIATE_BUILT)

# After BOTH snapshots and intermediate: a list of Assets means all of them must be updated.
# Also runs the core singular tests in tests/marts (they read models of several layers).
dbt_layer_dag(
    "dwh_core",
    ["path:models/marts/core", "path:tests/marts"],
    schedule=[SNAPSHOTS_BUILT, INTERMEDIATE_BUILT],
    outlet=CORE_BUILT,
    detach_multi_model_tests=True,
)

# After core. These 2 DAGs start at the same time.
dbt_layer_dag("dwh_finance", ["path:models/marts/finance"], schedule=[CORE_BUILT])
dbt_layer_dag("dwh_product", ["path:models/marts/product"], schedule=[CORE_BUILT])
