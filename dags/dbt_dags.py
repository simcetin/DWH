"""Two Airflow DAGs for this repo's dbt project, built with Cosmos.

- dwh_seeds:  loads all dbt seeds. Start it by hand.
- dwh_models: builds all dbt models. Starts automatically after dwh_seeds
              finishes successfully (seeds DAG --> models DAG).

The link between them is an Airflow Asset: the last task of dwh_seeds marks
SEEDS_LOADED as updated, and dwh_models is scheduled on that Asset.
"""

from datetime import datetime
from pathlib import Path

from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.sdk import DAG, Asset
from cosmos import DbtTaskGroup, ExecutionConfig, ProfileConfig, ProjectConfig, RenderConfig

REPO_DIR = Path(__file__).resolve().parent.parent

SEEDS_LOADED = Asset("dwh://seeds_loaded")

project_config = ProjectConfig(
    dbt_project_path=REPO_DIR,
    # Cosmos runs dbt from a temporary copy of the project, so give dbt
    # the full path to the DuckDB file in the repo.
    env_vars={"DBT_DUCKDB_PATH": str(REPO_DIR / "dwh.duckdb")},
)
profile_config = ProfileConfig(
    profile_name="dwh",
    target_name="dev",
    profiles_yml_filepath=REPO_DIR / "profiles.yml",
)
execution_config = ExecutionConfig(
    dbt_executable_path=str(REPO_DIR / ".venv" / "bin" / "dbt"),
)

common_dag_args = dict(
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_tasks=1,  # DuckDB allows only one writer at a time
)


with DAG(dag_id="dwh_seeds", schedule=None, **common_dag_args):
    seeds = DbtTaskGroup(
        group_id="seeds",
        project_config=project_config,
        profile_config=profile_config,
        execution_config=execution_config,
        render_config=RenderConfig(select=["resource_type:seed"]),
    )
    # Runs only if every seed succeeded; this is what starts dwh_models.
    seeds_done = EmptyOperator(task_id="seeds_done", outlets=[SEEDS_LOADED])

    seeds >> seeds_done


with DAG(dag_id="dwh_models", schedule=[SEEDS_LOADED], **common_dag_args):
    DbtTaskGroup(
        group_id="models",
        project_config=project_config,
        profile_config=profile_config,
        execution_config=execution_config,
        render_config=RenderConfig(select=["resource_type:model"]),
    )
