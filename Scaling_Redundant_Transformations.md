# Problem 1: Analysts are creating redundant transformations in their queries

Analysts write the same transformation again in their own queries, even when a data model already does it.
I see 4 possible root causes. For each one, I describe what it causes, what I would do, and the expected
impact. Where possible, I use examples from the dbt project in this repository.

| # | Root cause | What I would do |
|---|---|---|
| 1 | Data models are not at the grain analysts need | Build models at the most detailed (atomic) grain first |
| 2 | Analysts do not trust or understand the existing models | Offer certified data products: tested, documented once, and owned |
| 3 | No semantic layer for the most used metrics | Define the company-wide metrics once, in a semantic layer |
| 4 | Analysts can read staging and intermediate models directly | Allow analysts and domain models to use only the certified layer |

---

## 1. Data models are not at the grain analysts need

### Why it happens
The existing models are not reusable or easy to explore. For example, a model is only available at a
monthly or aggregated grain, but the analyst needs a daily or per-card view.

### What it causes
The analyst creates a new query or table that repeats a transformation that an existing model already does,
only at a different grain.

### What I would do
- Before creating a new model, understand the business need of today and the likely needs of the future.
- Build models at the **most detailed (atomic) grain** that the business needs, for example one row per transaction or one row per card and day.
- Build aggregated models on top of these detailed models, not from the raw data again.

Example from this project: `fct_card_usage_daily` has one row per card and day. Daily, weekly and monthly
numbers of used cards all come from this one table.

### Expected impact
Analysts reuse the detailed models and only add an aggregation in their query. They do not need to rebuild the whole transformation. A new report at a higher grain becomes a simple `group by`.

---

## 2. Analysts do not trust or understand the existing models

### Why it happens
- **No agreed definitions.** There is no process to approve key business definitions company-wide, so each
  team defines "active card", "net transaction amount" or "card usage" in its own way.
- **No single documentation.** Columns are documented in different places, with different words, or not at all.
- **No clear ownership.** Nobody is named as responsible for a model or for the business logic inside it.

### What it causes
- Analysts cannot find data they trust, so they write their own logic.
- Example: "active card" is described in one way in one model and in another way in a second model. The analyst does not know which description is correct, so they write their own version.
- The analyst has questions about a model (how often is it refreshed, what does a column really mean?) but
  there is no point of contact. Without answers, the analyst creates a separate model, which most likely repeats the same logic.

### What I would do
Offer **certified data products**: models that are approved company-wide, tested, documented once, and owned.

**Certify.** Mark the models, columns and business definitions that are certified company-wide in the `.yml`
files. Every certified model must be tested and documented.

**Document once.** Document each column at the earliest layer where it exists, and reuse that description in
every layer with dbt doc blocks:

- A column that comes from the source without changes is documented in the **staging** layer.
- A column that is calculated by a transformation is documented in the layer where it is calculated, usually the **core** layer.
- All later layers and domains reuse the same doc block.

This gives one definition for every dimension and metric. Example from this project: the doc block
`dim_virtual_cards__is_activated` describes an activated card, and every model that has this column uses it.

**Name the owners.** In the `.yml` file of each model, name:

- the **pipeline owner**: the team that builds, runs and maintains the model
- the **logic owner**: the team that decides the business logic

For columns with a complex transformation, I would also name the team that owns that specific rule.

Example from this project:

```yaml
- name: fct_card_transactions
  config:
    meta:
      certified: true
      pipeline_owner: analytics-engineering
      logic_owner: finance-team   # owns the rule: a transaction counts only while the card is ACTIVE
```

### Expected impact
- Analysts trust the certified models, so they reuse them instead of starting from scratch.
- "Active card" has the same description everywhere, so data consumers know exactly what a column means.
- When analysts have doubts about a model, they know who to ask, and they reuse the model with confidence.

---

## 3. No semantic layer for the most used company-wide metrics

### Why it happens
Models give columns, not metrics. Each analyst and each dashboard calculates metrics such as activation rate,
cards used or net spend in their own SQL: their own filters, their own time windows, their own way to divide.

### What it causes
- The same metric shows different numbers in different dashboards.
- Metrics are counted or added up in different ways. Two simple examples:
  - **Counting the same card twice (distinct count).** Card A is used on Monday, Tuesday and Wednesday. Each
    day shows 1 used card. An analyst adds the 3 days and reports 3 used cards for the week. The correct answer is 1, because it is the same card.
  - **Adding up amounts (sum).** A card makes a purchase of €100 and later gets a refund of €30. One analyst
    sums only the purchases and reports €100. Another analyst sums all transactions and reports €70. The
    company definition of net spend is €70, but 2 dashboards now show 2 different numbers.
- Every new dashboard repeats the metric logic again.

### What I would do
- Define the most used company-wide metrics **once**, in a semantic layer (for example the dbt Semantic
  Layer). Each metric has a definition, a calculation, the dimensions it can be split by, and the time grains
  it supports (day, week, month).
- Build the metrics only on certified facts and dimensions, for example `fct_card_usage_daily`,
  `fct_card_transactions`, `dim_accounts` and `dim_virtual_cards`.
- Give each metric a logic owner, the same as for models.
- Connect the BI tool to the semantic layer, so dashboards ask for a metric by name instead of writing SQL.

### Expected impact
- A metric shows the same number in every dashboard and every analysis.
- Analysts ask for "cards used by industry per month" without writing the logic. The semantic layer applies
  the correct aggregation, for example a distinct count over the whole month.
- A change to a metric definition is made in one place, and every dashboard follows.

---

## 4. Analysts can read staging and intermediate models directly

### Why it happens
Nothing stops analysts or new models from reading staging and intermediate models. These layers are internal building blocks, not finished data products.

### What it causes
- Analysts build their queries on staging or intermediate models and repeat logic that the certified models
  already contain, for example the conversion to EUR or the rule that a transaction counts only while the
  card is ACTIVE. Their numbers then differ from the certified numbers.
- Analyst queries break when something changes in the layers below the certified models:
  - The core team changes a staging or intermediate model, for example it renames a column or splits a model.
  - The source system changes. For example, a column is dropped from the raw `transactions` table, or the type
    of `amount` changes from a number to text.

  Example: the source renames `currency` to `currency_iso`. Every analyst query that reads
  `stg_core_banking__transactions` directly fails. With the certified layer, only the core team adapts the
  staging model, and `fct_card_transactions` keeps the column `currency_code`. Analyst queries on the
  certified fact keep working.

### What I would do
Allow analysts and domain models to use **only the certified layer**, on 2 levels:

- **In dbt:** use groups and access levels. Staging and intermediate models are `private` to the core group.
  Domain models (Product, Finance) can only build on `public` models, which are the certified core facts and
  dimensions. This is already set up in this project.

  Example: a Finance analyst wants to create a new reporting model, `mart_refunds_daily`.

  **Not allowed:** reading the staging table directly.

  ```sql
  select transaction_date, sum(amount) as refund_amount
  from {{ ref('stg_core_banking__transactions') }}
  where amount < 0
  group by transaction_date
  ```

  dbt stops the build before any SQL runs:

  > *... attempted to reference node model.dwh.stg_core_banking__transactions, which is not allowed because
  > the referenced node is private to the 'core' group.*

  This model would also give wrong numbers: the amounts are in different currencies, and it includes
  transactions on cards that were not ACTIVE.

  **Allowed:** reading the certified fact.

  ```sql
  select transaction_date, sum(amount_eur) as refund_amount_eur
  from {{ ref('fct_card_transactions') }}
  where is_refund
  group by transaction_date
  ```

  `fct_card_transactions` already has the amount in EUR, only counts transactions on ACTIVE cards, and has
  the account segment at the time of the transaction. The analyst only writes the aggregation.
- **In the warehouse:** give analyst roles read access only to the marts schemas (core, product, finance),
  not to the raw, staging and intermediate schemas. This can be managed with the dbt `grants` configuration
  per folder.

### Expected impact
- Analysts start from certified models, so they do not rebuild existing logic.
- Numbers stay consistent, because all analyses use the same rules.
- When the source system changes (a dropped column, a renamed column, a new data type), the core team adapts
  the staging and intermediate models. The certified models keep the same columns, so analyst queries do not
  break.
- The core team can also improve staging and intermediate models without breaking analyst queries.
