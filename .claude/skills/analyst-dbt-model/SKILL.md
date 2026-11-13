---
name: analyst-dbt-model
description: Use when a data analyst wants to create or change a dbt model in this project, for example a new Product or Finance mart, a new metric table, or a report table built on the certified core facts and dimensions. Guides the analyst through the project conventions (layers, naming, SQL style, star schema, business definitions, doc blocks, tests, access and ownership) and only allows changes inside the analyst's domain mart folder.
---

# Analyst dbt model creation

## Who this skill is for

This skill is used by **data analysts** who want to create a new dbt model in this project. Act as a
careful Analytics Engineering colleague: help the analyst build the model, and make sure it follows the
project conventions below. Explain each decision in plain words, because the analyst may be new to dbt.

`README.md` gives a short overview of the project design (layers, star schema, documentation, access,
ownership). The detailed conventions that a new model must follow are in this skill.

## What analysts are allowed to do

**Allowed:**

- Create and change models in their own domain folder: `models/marts/product/` or `models/marts/finance/`.
- Add doc blocks to the `_<domain>__docs.md` file of that folder.
- Add model entries and tests to the `_<domain>__models.yml` file of that folder.
- Add singular tests in `tests/product/` or `tests/finance/`.
- Build from **public** models only: the core dimensions and facts in `models/marts/core/`, and other
  public domain marts.

**Not allowed** (stop and explain that Analytics Engineering owns these):

- Creating or changing anything in `models/staging/`, `models/intermediate/`, `models/marts/core/`,
  `snapshots/`, `seeds/`, `macros/` or `dags/`.
- Changing `dbt_project.yml`, `models/_groups.yml`, sources, groups or access levels.
- Reading staging or intermediate models (`ref('stg_...')`, `ref('int_...')`) or raw data (`source(...)`).
  dbt blocks this with access rules. Never change `access` to work around it.
- Redefining an agreed business definition (see "Business definitions" below). Reuse the column that
  contains it.
- Running anything with `--target prod`, running `--full-refresh` on production, or dropping tables.
- Committing or pushing to Git, unless the analyst explicitly asks for it.

If the analyst needs something that is not allowed (a new raw column, a change to a core model, a new
domain), do not build a workaround. Write a short request for Analytics Engineering that explains what is
needed and why, and stop.

## Project conventions

### Layers and where analysts work

```
raw → staging → intermediate → core marts (dim_, fct_) → domain marts (mart_)
```

Analysts create **domain marts** only. A domain mart reads **only** core dimensions and facts (and other
public domain marts). It never reads staging, intermediate or raw data.

| Domain | Folder | Schema | Group | Tag | Technical owner |
|---|---|---|---|---|---|
| Product | `models/marts/product/` | `mart_product` | `product` | `product` | `product-analytics` |
| Finance | `models/marts/finance/` | `mart_finance` | `finance` | `finance` | `finance-analytics` |

The folder sets the group, the schema, `access: public` and the `table` materialization automatically. Do
not set these in the model. In dev, the schema gets the prefix `main_` (for example `main_mart_product`).
The core dimensions and facts are in the schema `core`.

### Certified core models to build on

| Model | Grain | Use it for |
|---|---|---|
| `dim_date` | 1 row per calendar day | Date spines, calendar attributes |
| `dim_accounts` | 1 row per account, current values | Current industry, plan, country |
| `dim_accounts_history` | 1 row per account and version | Account values at a past date |
| `dim_virtual_cards` | 1 row per card, current values | Current status, type, `is_activated` |
| `dim_virtual_cards_history` | 1 row per card and version | Card values at a past date |
| `fct_card_transactions` | 1 row per counted transaction | Spending, with segments at transaction time |
| `fct_card_usage_daily` | 1 row per card and day | Card usage (`is_used`), cards created (`is_creation_day`) |
| `fct_accounts_cards` | 1 row per card and unchanged period | Point-in-time questions about cards and accounts |

History dimensions: the version valid at time T is `valid_from <= T and T < valid_to`. The current version
has `is_current = true`.

### Business definitions

These are agreed with the logic owners. Reuse the column; never calculate them again in a new way.

| Definition | Rule | Column to reuse | Logic owner |
|---|---|---|---|
| Activated card | The card's current status is ACTIVE | `dim_virtual_cards.is_activated` | Product |
| Used card | At least 1 purchase on a day, made while the card was ACTIVE. Refunds do not count | `fct_card_usage_daily.is_used` | Product |
| Counted transaction | Only transactions made while the card was ACTIVE | every row of `fct_card_transactions` | Finance |
| Amount in EUR | Amount divided by the ECB rate of the transaction day | `fct_card_transactions.amount_eur` | Finance |
| Net spend | Purchases minus refunds, in EUR | `sum(amount_eur)` on `fct_card_transactions` | Finance |

### Naming

| Item | Rule | Example |
|---|---|---|
| Domain mart | `mart_<subject>_<grain>` | `mart_refunds_daily` |
| Primary key | `<entity>_id` | `card_id` |
| Boolean | `is_` or `has_` prefix | `is_refund` |
| Date | `_date` suffix, or `date_day` for calendar days | `transaction_date` |
| Timestamp | `_at` suffix | `card_created_at` |
| Amount in EUR | `_eur` suffix | `refund_amount_eur` |
| Count | `<thing>_count` or a plural noun | `transaction_count`, `cards_used` |
| Singular test | `assert_<model>_reconciles.sql` | `assert_mart_refunds_daily_reconciles.sql` |

Never use reserved words (like `date`) as column names.

### SQL style

- A header comment with the grain and the business rules.
- A config block with the domain tag: `{{ config(tags=['product']) }}`.
- One CTE per input, selecting only the needed columns by name. Never `select *` from a `ref()`.
- Columns grouped by type with a comment per group, in this order: ids, strings, numerics, booleans, dates,
  timestamps.
- Prefix columns with the CTE name when a query uses more than 1 input.
- Conditional counts and sums with `case when`: `sum(case when is_used then 1 else 0 end)`.
- Cross-database date macros where they exist: `{{ dbt.dateadd(...) }}`, `{{ dbt.datediff(...) }}`.
- Lowercase keywords, 4 spaces of indentation, and end with `select * from final`.

### Documentation

- Every description is a doc block in the folder's `_<domain>__docs.md` file. YAML only references it.
- Doc block names: `<full model name>` for the model, `<full model name>__<column>` for columns.
- A column that already exists in another model reuses that model's doc block. Only new columns get a new
  block.

## Workflow

Follow these steps in order. Do not skip step 1 and step 2.

### Step 1: Understand the need

Ask the analyst, if it is not already clear:

1. **The business question.** What should the model answer?
2. **The domain.** Product or Finance? This decides the folder, the group and the tag.
3. **The grain.** What is 1 row? For example "1 row per day and industry".
4. **The measures.** Which numbers, and their exact definition (for example: are refunds included?).
5. **The segments.** Which dimensions to split by, and whether they should be the values **at the time of
   the event** or the **current** values.
6. **Zero-filled or not.** For daily or monthly models: should days without activity appear with 0?
7. **The logic owner.** Which business team decides the definitions?

### Step 2: Check what already exists

Before writing any SQL:

1. Search `models/marts/` for models that already answer the question, or that are at a more detailed grain
   and only need an aggregation. **If a model already answers it, tell the analyst and stop.**
2. Read the certified core models the new model would use, and their YAML in `models/marts/core/_core__models.yml`:
   - `dim_date`, `dim_accounts`, `dim_accounts_history`, `dim_virtual_cards`, `dim_virtual_cards_history`
   - `fct_card_transactions`, `fct_card_usage_daily`, `fct_accounts_cards`
3. Check which business definitions are already calculated (`is_activated`, `is_used`, `amount_eur`, the
   ACTIVE-only rule) and reuse those columns.
4. Search the `.md` files for existing doc blocks of the columns you will output.

### Step 3: Design the model and confirm it

Propose to the analyst, in a short table:

- the model name: `mart_<subject>_<grain>`, for example `mart_refunds_daily`
- the folder: `models/marts/<domain>/`
- the grain and the columns, with their type and source
- the input models (only public models)
- the tests

Wait for the analyst to confirm before you write files.

### Step 4: Write the SQL

Create `models/marts/<domain>/<model_name>.sql` following the SQL style above:

```sql
-- <What the model contains and its grain.>
-- <Business rules and important notes, for example which measures cannot be summed across days.>
{{ config(tags=['<domain>']) }}

with

<input_name> as (

    select
        <only the columns you need, by name>

    from {{ ref('<public core model>') }}

),

final as (

    select
        -- ids
        -- strings
        -- numerics
        -- booleans
        -- dates
        -- timestamps

    from <input_name>

)

select * from final
```

Rules to check:

- One CTE per input, with named columns only. Never `select *` from a `ref()`.
- Columns grouped by type with a comment per group: ids, strings, numerics, booleans, dates, timestamps.
- Column names follow the naming rules above: `_id`, `is_`, `_date`, `_at`, `_eur`.
- Conditional counts with `sum(case when <condition> then 1 else 0 end)`.
- Zero-filled daily models: build a spine from `dim_date` (cross join with the segment combinations) and
  `left join` the aggregated data, with `coalesce(..., 0)`.
- Never sum a distinct count across days. If a measure is a distinct count, say so in the header comment.

### Step 5: Document the model

1. In `models/marts/<domain>/_<domain>__docs.md`, add:
   - a model block named exactly like the model, with the grain and the business rules
   - a column block `<model_name>__<column>` **only for new columns**
2. For every column that already exists in another model, **reuse its doc block**. Examples:
   - `date_day` → `dim_date__date_day`
   - `industry` → `stg_core_banking__accounts__industry`
   - `merchant_category` → `stg_core_banking__transactions__merchant_category`
3. If a new column has a business rule, add one line to its doc block: "Business owner of this definition:
   <team>."

### Step 6: Add the YAML entry and tests

In `models/marts/<domain>/_<domain>__models.yml`, add:

```yaml
  - name: <model_name>
    description: '{{ doc("<model_name>") }}'
    config:
      meta:
        pipeline_owner: [<domain>-analytics, analytics-engineering]
        logic_owner: <domain>-team
    data_tests:
      - unique_combination_of_columns:
          arguments:
            combination_of_columns: [<the grain columns>]
    columns:
      - name: <column>
        description: '{{ doc("<existing or new doc block>") }}'
        data_tests: [not_null]
```

- Test the grain with `unique_combination_of_columns`, or `unique` and `not_null` for a single key.
- Add `relationships` tests for keys that point to a dimension.
- For a column with a business rule, add `config: meta: business_owner: <team>`.
- For a column that can identify a person, add `config: meta: contains_pii: true`.
- Do **not** add `certified: true`. Certification is decided by the logic owner and Analytics Engineering.

For an aggregated mart, also add a reconciliation test in `tests/<domain>/assert_<model_name>_reconciles.sql`
that compares the mart totals with the fact totals:

```sql
{{
    config(
        tags=['<domain>'],
        meta={'owner': '<domain>-analytics'}
    )
}}

-- <model_name> must contain every row of <fact>: same count and same amount.
with

mart_totals as (
    select sum(<measure>) as <measure>
    from {{ ref('<model_name>') }}
),

fact_totals as (
    select <same calculation> as <measure>
    from {{ ref('<fact>') }}
)

select *
from mart_totals
cross join fact_totals
where mart_totals.<measure> <> fact_totals.<measure>
```

### Step 7: Build and test in dev

Run only in the dev target (the default):

```bash
.venv/bin/dbt build --select <model_name>
```

Then check the output with the analyst:

- all tests pass
- the row count matches the expected grain
- the totals match the source fact

If a test fails, fix the model. Do not delete or weaken a test to make it pass.

### Step 8: Summarize

Tell the analyst:

- which files you created or changed
- the grain and the columns of the new model
- the test results and the key numbers
- the next step: open a pull request, which the domain owner reviews

## Final checklist

Before you finish, confirm each point:

- [ ] The model does not duplicate an existing model.
- [ ] It is in `models/marts/product/` or `models/marts/finance/`.
- [ ] It only reads public core or domain models.
- [ ] The name follows `mart_<subject>_<grain>`.
- [ ] The SQL follows the project style: header comment, domain tag, named columns, grouped by type.
- [ ] Agreed business definitions are reused, not redefined.
- [ ] Every column has a doc block, and existing doc blocks are reused.
- [ ] The grain is tested, and aggregated marts have a reconciliation test.
- [ ] `pipeline_owner` and `logic_owner` are set; `contains_pii` and `business_owner` where needed.
- [ ] `dbt build --select <model_name>` passes in dev.
