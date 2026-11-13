# Scaling and Improvement

## Context

Today, 15 data analysts use the data models. Over the next 12 months, the team will grow to 30 analysts.
We see 3 problems:

1. Analysts write the same transformations again and again in their own queries.
2. It is hard to know which models are actually used.
3. New analysts need too much time before they can work on their own.

These problems get worse when the team doubles. Twice as many analysts write twice as many copies of the
same logic, create more models nobody tracks, and ask the senior analysts twice as many onboarding questions.

## What is already in place

The dbt project for Part 1 already gives a base for the improvements below:

| Foundation | Where it is |
|---|---|
| Layers with clear roles: staging, intermediate, core facts and dimensions, domain marts | `models/` |
| One definition for key business rules, for example "activated card", "used card", amount in EUR | `dim_virtual_cards`, `fct_card_usage_daily`, `int_transactions_converted_to_eur` |
| Domains with owners: core, product, finance | `models/_groups.yml` (dbt groups) |
| Clear interfaces: staging and intermediate are private, core and domain marts are public | `dbt_project.yml` (dbt access) |
| One description per column, reused in every layer | `.md` doc blocks |
| A business owner for every business rule, for example Product owns "activated card" | `meta.business_owner` on the column (or model) where the rule is calculated |
| Certified data products: core dimensions and facts, and 2 domain marts | `meta.certified`, `meta.pipeline_owner` and `meta.logic_owner` on the model |
| Tests on every primary key, relationships and reconciliations | model YAML files, `tests/` |
| Separate dev and prod schemas | `macros/generate_schema_name.sql` |
| Tags per domain, for separate Airflow DAGs | model configs |

## Priorities at a glance

| Priority | Improvement | Main problem it solves | Timing |
|---|---|---|---|
| 1 | Shared metric definitions and certified data products | Redundant transformations | Months 1 to 3 |
| 2 | Self-service onboarding | Slow onboarding | Months 2 to 5 |
| 3 | Model usage tracking and lifecycle | Unknown model usage | Months 4 to 6, then ongoing |

Why this order:

- **Redundant logic comes first.** When 2 analysts calculate "active cards" in 2 ways, the business gets 2
  different numbers for the same question. This hurts trust in the data, and the number of copies grows with
  every new analyst.
- **Onboarding comes second.** It must be ready before most new analysts join. It also depends on
  improvement 1: onboarding should teach the shared metrics, not the old copies.
- **Usage tracking comes third.** It becomes more important as the project grows. The owners per model
  already exist (dbt groups), so this work can start in parallel with improvement 2.

---

## Improvement 1: Shared metric definitions and certified data products

### What I would do

- Find the transformations that analysts repeat in their queries, and move them into dbt models.
- Define the most important business metrics once, in a semantic layer (for example the dbt Semantic Layer),
  so the BI tool and the analysts use the same calculation. Examples: cards created, cards used,
  activation rate, net spend in EUR.
- Give every business rule a **business owner**: the team that decided the definition. Anyone who wants to
  understand a definition, or to change it, aligns with that team first. The business owner is separate from
  the technical owner (the dbt group owner), who maintains the code.
- Mark the shared models as **certified data products**: their definitions, dimensions and metrics are
  approved company-wide, so they can be used in official reporting. Certified is stronger than public:
  public means other domains may build on a model, certified means the business owners have approved it.
- Let analysts add models themselves in their domain folder, through a pull request that the domain owner
  reviews.

### Expected impact

- **One number per metric.** "Activation rate" gives the same result in every dashboard and every analysis.
- **Less time per analysis.** Analysts start from a tested model instead of writing 50 lines of joins and
  filters.
- **Lower warehouse cost.** Heavy joins run once per day in dbt, not in every analyst query.
- **Faster reviews.** Reviewers check a short query on a known model, not a long query with its own logic.

### Conventions already applied in this project

**Business owner of a rule.** The owner is set on the column where the rule is calculated, not on every
column that reuses it. The doc block of the column also names the owner, so it is visible in the catalog.

```yaml
- name: is_activated
  description: '{{ doc("dim_virtual_cards__is_activated") }}'
  config:
    meta:
      business_owner: product-team   # owns the definition of an activated card
```

| Business rule | Where it is calculated | Business owner |
|---|---|---|
| Activated card: the current status is ACTIVE | `dim_virtual_cards.is_activated` (and per version in `dim_virtual_cards_history`) | Product |
| Used card: at least 1 purchase while the card is ACTIVE | `fct_card_usage_daily.is_used` | Product |
| Amount in EUR: amount divided by the ECB rate of the day | `int_transactions_converted_to_eur.amount_eur` | Finance |
| A transaction counts only while the card is ACTIVE | `fct_card_transactions` (model level, as `logic_owner`) | Finance |

**Certified data products.** A certified model has `certified: true` and 2 owners:

- **Pipeline owner:** the team that builds, runs and maintains the model. Contact them when the model fails,
  is late or has a bug. Analytics Engineering is a pipeline owner of every certified model, because it
  maintains the data platform that all models run on. Domain marts also have the domain's analytics team.
- **Logic owner:** the team that decides the business logic of the model. Align with them before changing
  what the model calculates.

A column can have its own business owner when one rule in the model belongs to another team. For example,
the logic owner of `dim_virtual_cards` is Analytics Engineering, but `is_activated` belongs to Product.

```yaml
- name: fct_card_usage_daily
  config:
    meta:
      certified: true
      pipeline_owner: analytics-engineering   # builds, runs and maintains the model
      logic_owner: product-team               # decides the business logic
```

| Certified models | Pipeline owner | Logic owner |
|---|---|---|
| `dim_date`, `dim_accounts`, `dim_accounts_history`, `fct_accounts_cards` | Analytics Engineering | Analytics Engineering |
| `dim_virtual_cards`, `dim_virtual_cards_history` | Analytics Engineering | Analytics Engineering (`is_activated`: Product) |
| `fct_card_transactions` | Analytics Engineering | Finance |
| `fct_card_usage_daily` | Analytics Engineering | Product |
| `mart_cards_daily` | Product Analytics, Analytics Engineering | Product |
| `mart_spending_patterns_daily` | Finance Analytics, Analytics Engineering | Finance |

A model can only be certified when it meets this checklist:

1. `access: public`
2. Tests on the primary key and on the relationships to the dimensions
3. A doc block for every column
4. A pipeline owner and a logic owner, and a business owner for every column rule that belongs to another team
5. Later: an enforced dbt contract (fixed column names and types). This is not added yet.

### How I would implement it

1. **Find the repeated logic.** Export the warehouse query history of the last 90 days. Group queries by the
   tables they join and the filters they use. List the 20 most repeated patterns. Confirm the list in short
   interviews with 5 analysts.
2. **Decide where each pattern belongs.**
   - A building block that only other models need becomes an intermediate model.
   - A result that analysts or dashboards use directly becomes a public model in a domain mart folder.
3. **Build and test the models.** Use the existing conventions: tests on the primary key, relationships to
   the dimensions, and doc blocks for every column.
4. **Define the metrics.** Create semantic models on the core facts (`fct_card_transactions`,
   `fct_card_usage_daily`) and dimensions. Define the top 10 metrics with their owner and business
   definition. Connect the BI tool to the semantic layer.
5. **Protect the certified models.** Check the certification checklist in CI: a small script on the dbt
   `manifest.json` fails the build when a model with `certified: true` misses a test, a doc block, a
   pipeline owner or a logic owner. As a next step, add enforced contracts to certified models, and use model versions for
   breaking changes, so consumers can move to the new version on their own schedule.
6. **Set up the contribution process.** Add a pull request template and a CI job that builds and tests the
   changed models and everything downstream (`dbt build --select state:modified+`).
7. **Remove the copies.** Point the dashboards to the new models and metrics. Track how many old queries
   remain.

### How I would measure success

| Measure | Target after 6 months |
|---|---|
| Top business metrics defined in the semantic layer | 10 of 10 |
| Share of BI queries that read certified models | above 80% (measure the starting point first) |
| Repeated query patterns from step 1 still in use | below 5 of 20 |
| Business rules in certified models with a business owner | 100% |

---

## Improvement 2: Self-service onboarding

### What I would do

Give new analysts one clear path from their first day to their first merged pull request:

- A searchable data catalog: the hosted dbt documentation, built from the doc blocks that already exist.
- An onboarding guide in the repository: setup, layers, naming rules, domains and owners, how to contribute.
- A glossary of business definitions, for example activated card, used card and net spend.
- A personal dev environment for each analyst.
- 3 starter tasks and a buddy from the same domain.

### Expected impact

- **Shorter onboarding.** Goal: a new analyst delivers a first analysis and a first merged pull request
  within 2 weeks. I would measure the current time first, to compare.
- **Fewer repeated questions to senior analysts.** The answers are in the catalog and the guide.
- **Safer first contributions.** A personal dev schema means new analysts cannot break shared tables.
- **Consistent work from the start.** New analysts learn the shared metrics from improvement 1, not old copies.

### How I would implement it

1. **Publish the catalog.** Generate the dbt documentation after every production run (an extra Airflow
   task) and host it, or use dbt Explorer. The doc blocks are the single source for every description.
2. **Write the onboarding guide** (`ONBOARDING.md` in the repository):
   - setup in a few commands (install, connect, first `dbt build`)
   - where the data comes from and what each layer does
   - naming rules (`stg_`, `int_`, `fct_`, `dim_`, `mart_`) and the doc block convention
   - which domain owns what, and who to ask
   - how to open a pull request
3. **Create the glossary.** One page that lists every certified metric with its definition, owner and model.
   It uses the same doc blocks, so the catalog and the glossary never disagree.
4. **Give every analyst a personal dev schema** (for example `dev_<name>_staging`). The schema macro already
   separates dev from prod, so this is a small change in the profile.
5. **Prepare 3 starter tasks:** add a test, add a documented column, build a small mart. Each task touches
   one part of the workflow.
6. **Collect feedback.** Ask each new analyst after 30 days what was missing, and update the guide.

### How I would measure success

| Measure | Target |
|---|---|
| Days from start to first merged pull request | 10 working days or less |
| New analysts with a working dev environment on day 1 | 100% |
| Onboarding feedback score after 30 days | 4 of 5 or higher |

---

## Improvement 3: Model usage tracking and lifecycle

### What I would do

- Measure which models are read, how often, by which people and by which dashboards.
- Declare every important dashboard in dbt as an **exposure**, so the lineage goes from the source table to
  the dashboard.
- Introduce a lifecycle rule: models that nobody uses are deprecated and then removed.

### Expected impact

- **Smaller project.** Fewer models to maintain, test and document.
- **Shorter runs and lower cost.** Unused models stop running every day.
- **Safer changes.** Before a change, the owner sees which dashboards and people depend on the model.
- **Faster search for analysts.** Fewer near-duplicate models means the right model is easier to find.

### How I would implement it

1. **Collect usage data.** Load the warehouse access history into an observability schema. Examples:
   `ACCESS_HISTORY` in Snowflake, `INFORMATION_SCHEMA.JOBS` in BigQuery, the system query tables in Redshift.
   Add metadata from the BI tool (which dashboards read which tables).
2. **Link usage to dbt models.** Use the dbt `manifest.json` to map each table to its model, owner and domain.
   A package such as `dbt_artifacts` or Elementary can store run results and test results next to it.
3. **Declare exposures.** For each important dashboard, add a dbt exposure with its owner and the models it
   uses.
4. **Build a usage dashboard.** For each model: queries in the last 30 and 90 days, number of distinct users,
   dashboards that depend on it, build time and cost.
5. **Apply the lifecycle rule:**
   - no reads in 90 days: the owner gets a message
   - the owner confirms: set a `deprecation_date` on the model (dbt shows a warning to anyone who uses it)
   - 30 days later: remove the model
6. **Review per domain every month.** Each group owner (core, product, finance) reviews the usage of their
   models.

### How I would measure success

| Measure | Target after 6 months |
|---|---|
| Models with known usage (reads, users, dashboards) | 100% |
| Important dashboards declared as dbt exposures | 100% |
| Models with no reads in 90 days | below 10% of all models |

---

## Risks and how I would handle them

| Risk | How I would handle it |
|---|---|
| Analysts keep their own queries because they are faster to write | Make the certified models easier to use than a new query: good names, a glossary, examples in the catalog |
| The semantic layer does not support a metric the business needs | Start with the 10 most used metrics; keep a mart model as a fallback for complex cases |
| Usage data is incomplete, for example for queries from notebooks | Combine warehouse logs with BI metadata, and ask owners before removing a model |
| Too many pull requests for the core team to review | Domain owners review their own folders; the core team reviews only shared and public models |
