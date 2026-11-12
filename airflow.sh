#!/usr/bin/env bash
# Run Airflow for this repo only. All Airflow files (config, database, logs,
# login password) go to ./airflow_home, never to the shared ~/airflow.
# Usage: ./airflow.sh standalone      (or any other airflow command)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# `airflow standalone` starts its parts as separate `airflow` processes, so this
# repo's .venv must come first on PATH (only for this script, not your shell).
export PATH="$REPO_DIR/.venv/bin:$PATH"
export AIRFLOW_HOME="$REPO_DIR/airflow_home"
export AIRFLOW__CORE__DAGS_FOLDER="$REPO_DIR/dags"
export AIRFLOW__CORE__LOAD_EXAMPLES=False

exec "$REPO_DIR/.venv/bin/airflow" "$@"
