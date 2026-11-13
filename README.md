# DWH: virtual card analytics (dbt)

## Layering

Data flows in one direction:

```
raw (seeds) ──→ staging ──→ snapshots ─────────────────────┐
                   │       (history of overwritten sources) │
                   │                                        ↓
                   └──────→ intermediate ──────→ core marts (star schema) ──→ domain marts (product, finance)
```

| Layer | Prefix | Purpose | Materialization |
|---|---|---|---|
| Staging | `stg_<source>__<table>` | One model per source table: rename, cast, light cleaning. The only layer that reads raw data. | view (high-volume transactions: incremental) |
| Snapshots | `snp_<source>__<table>` | SCD2 history of sources that are overwritten on every load. They read the staging models, so the history has the cleaned column names, and they feed the history dimensions. | snapshot |
| Intermediate | `int_<entity>_<verb>` | Reusable logic steps, for example the join between transactions and FX rates | view |
| Core marts | `dim_`, `fct_` | The star schema: shared dimensions and facts | table (large facts: incremental) |
| Domain marts | `mart_<subject>_<grain>` | Aggregated tables for one domain, built only from core marts | table |

## Schema names

Each layer has its own schema:

| Layer | Schema |
|---|---|
| Raw data | `raw_core_banking`, `raw_ecb` (one schema per source system) |
| Staging | `staging` |
| Intermediate | `intermediate` |
| Snapshots | `snapshots` |
| Core marts | `core` |
| Product marts | `mart_product` |
| Finance marts | `mart_finance` |

## Modelling approach: star schema

The core layer is a dimensional model. Facts describe events at a clear grain, dimensions describe the
entities, and domain marts aggregate the facts.

| Model | Layer | Grain | Type |
|---|---|---|---|
| `dim_date` | Core | 1 row per day | Calendar |
| `dim_accounts`, `dim_virtual_cards` | Core | 1 row per account / card | Current state |
| `dim_accounts_history`, `dim_virtual_cards_history` | Core | 1 row per account / card and version | History (SCD2), from snapshots |
| `fct_card_transactions` | Core | 1 row per counted transaction | Transaction fact |
| `fct_card_usage_daily` | Core | 1 row per card and day | Periodic snapshot fact |
| `fct_accounts_cards` | Core | 1 row per card and period with unchanged card and account versions | Point-in-time history |
| `mart_cards_daily` | Product | 1 row per day, industry, plan and country | Aggregate of `fct_card_usage_daily`: cards created and cards used |
| `mart_card_activation_monthly` | Product | 1 row per month | All cards so far, cards active at the end of the month (activation rate), and cards used that month |
| `mart_spending_patterns_daily` | Finance | 1 row per day, industry, plan and merchant category | Aggregate of `fct_card_transactions`: transaction count and net spend in EUR |

- **History:** SCD2 dimensions have `valid_from`, `valid_to` and `is_current`. The version valid at time T is
  `valid_from <= T and T < valid_to`.
- **Point in time:** facts store the account and card attributes **valid at the time of the event**. Current
  values come from the current-state dimensions.
- **Domain marts** read only core facts and dimensions. They have every calendar day for every segment
  combination, with 0 when nothing happened.

## Documentation

- Every description is a **doc block** in a `.md` file. YAML files only reference it:
  `description: '{{ doc("dim_virtual_cards__is_activated") }}'`.
- A column is documented **once**, where it is created: in staging when it comes from the source, or in the
  model where it is calculated. All later models reuse the same block.
- Doc blocks are named `<full model name>__<column>`, so the name shows where a column comes from.

This gives one definition for every column across all layers and domains.

## Access and domains

The project follows a data mesh approach. Each folder belongs to a domain (a dbt **group**) with an owner:

| Domain | Owner | Contains |
|---|---|---|
| `core` | Analytics Engineering | staging, intermediate, snapshots, core marts |
| `product` | Product Analytics | Product marts |
| `finance` | Finance Analytics | Finance marts |

Access levels define what other domains may build on:

- **Private:** staging and intermediate. Only the core domain may use them.
- **Public:** core marts and domain marts. Any domain may use them.

dbt enforces this when it builds: a Product or Finance model that reads a staging model fails. Domains build only on the certified core models.

## Ownership

Ownership is recorded as metadata in the YAML files:

| Key | Meaning |
|---|---|
| `certified: true` | The model is approved company-wide for official reporting |
| `pipeline_owner` | The team that builds and maintains the model. Analytics Engineering is always included. |
| `logic_owner` | The team that decides the business logic, for example Finance for spending rules |
| `business_owner` | On a column: the team that owns one specific rule, for example Product owns "activated card" |
| `contains_pii` | On a column: it can identify a person |

Analysts can create new domain marts with an AI skill that applies these conventions:
`.claude/skills/analyst-dbt-model/`.
