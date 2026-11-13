# Measuring the success of the data models


## 1. Trustworthy

A model is trustworthy when its data is correct, up to date, and the same number means the same thing
everywhere.

### Elementary: the main source for trust KPIs

**Elementary** is a dbt package, and it is installed in this project (`packages.yml`). After every dbt run, it
stores the results in tables in the warehouse (schema `elementary`). Because the results stay in tables, most
trust KPIs below are simple SQL queries on these tables.

| Elementary table | What it contains |
|---|---|
| `model_run_results` | One row per model run: status (success or error), start and finish time, execution time, the model's dbt group, owner and tags |
| `elementary_test_results` | One row per test run: status (pass, warn, fail), the model and column tested, the number of failing rows |
| `dbt_source_freshness_results` | The result of every source freshness check |
| `dbt_invocations` | One row per dbt run (`dbt build`, `dbt run`, `dbt test`), with its start and end time |
| `dbt_models`, `dbt_tests` | Metadata of every model and test, for example descriptions, owners and tags |

### KPIs

| KPI | How I measure it |
|---|---|
| Model run success rate of core models | Share of runs that succeed, per core model and per month (Elementary `model_run_results`) |
| Core models ready on time | Share of days on which every core model finished before the business day starts, for example 08:00 (Elementary `model_run_results`) |
| Execution time of core models | Average run time per core model and per month, to find models that get slower (Elementary `model_run_results`) |
| Test pass rate on certified models | Share of test runs that pass (Elementary `elementary_test_results`) |
| Test coverage of certified models | Share of certified models with tests on the primary key, the relationships, and a reconciliation test for aggregated marts |
| Freshness | Share of days on which every source passes `dbt source freshness` (Elementary `dbt_source_freshness_results`) |
| Pipeline success rate | Share of scheduled runs (Airflow) that finish without errors |
| Data incidents | Number of data problems reported by users per month, for example a wrong number in a dashboard |
| Time to fix an incident | Hours from the report to the fix |

### Example report: success rate of the core models

The monthly success rate, average execution time and last finish time of every core model:

```sql
select
    date_trunc('month', cast(generated_at as timestamp))                as run_month,
    name                                                                as model_name,
    count(*)                                                            as runs,
    sum(case when status = 'success' then 1 else 0 end)                 as successful_runs,
    round(100.0 * sum(case when status = 'success' then 1 else 0 end)
          / count(*), 1)                                                as success_rate_pct,
    round(avg(execution_time), 2)                                       as avg_execution_seconds,
    max(cast(execute_completed_at as timestamp))                        as last_finished_at

from elementary.model_run_results
where group_name = 'core'
group by 1, 2
order by 2
```

The same tables also give a monthly report per domain (`group_name` = `product` or `finance`), or per owner.

---

## 2. Discoverable

A model is discoverable when an analyst can find it, understand what it contains, and know who to ask.

| KPI | How I measure it |
|---|---|
| Documentation coverage | Share of models and columns with a description (doc block), from the dbt `manifest.json` |
| Ownership coverage | Share of models with a `pipeline_owner` and a `logic_owner` |
| Catalog usage | Number of analysts who open the data catalog (dbt docs) per week |
| "Where can I find" questions | Number of questions like "where is X?" or "which table should I use?" in the Slack channels |
| Time to first merged pull request | Working days from a new analyst's start to their first merged model |
| Analyst survey | Quarterly question: "How easy is it to find the data you need?" (1 to 5) |

**Example from this project:** every column is documented once with a doc block and reused in later
models, and every certified model has a pipeline owner and a logic owner. Both coverage KPIs can be
calculated directly from the `manifest.json`.

---

## 3. Actively used

A model is actively used when people and the dashboards they view query it regularly. Queries from service
accounts (scheduled BI refreshes, dbt builds and tests) do not count.

| KPI | How I measure it |
|---|---|
| Certified models in real use | Share of certified models queried by people, or by dashboards that people view, in the last 30 days |
| Share of queries on certified models | Share of analyst and BI queries that read certified models, instead of staging tables or private copies |
| Distinct users per model | Number of different people who use a model per month |
| Unused models | Share of models with no real use in the last 90 days |
| Dashboard views | Monthly views of dashboards built on certified models |
| Redundant query patterns | Number of repeated transformations found in analyst queries |

**Example from this project:** `fct_card_usage_daily` and `fct_card_transactions` are the base for both
domain marts. If they are used directly by analysts and by the Product and Finance dashboards, the share of
queries on certified models goes up.

---

## How I would collect the data

| Source | Gives |
|---|---|
| **Elementary** (dbt package, installed) | Model run results, execution and finish times, test results, source freshness, and model metadata, as tables in the warehouse |
| dbt `manifest.json` | Documentation and ownership coverage |
| Warehouse query history | Who queries which table and how often (service accounts excluded) |
| BI tool usage statistics | Dashboard views, and which tables each dashboard reads |
| Airflow | Run success and run duration |
| Slack and surveys | Questions from analysts, and how easy they find the data |

Elementary already loads the run and test results into the `elementary` schema after every run. I would add the warehouse query history and the BI usage statistics next to it, and build 1 dashboard with all KPIs.

## How I would use the KPIs

- **Every week:** Analytics Engineering checks trust KPIs (failed tests, freshness, failed runs) 
- **Every month:** Analytics Engineering and the domain owners (Product, Finance) review the discoverability and usage KPIs together, and decide which models to improve, certify or remove.
- **Every quarter:** compare the KPIs with the previous quarters to see the trend, and adjust the priorities.
