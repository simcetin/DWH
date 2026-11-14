{% docs snp_core_banking__accounts %}
History of customer accounts (slowly changing dimension, type 2).
One row per account and version.

### Why this snapshot exists
The source table `core_banking.accounts` is overwritten on every load. It only shows the
current state of each account, so an old value is lost when it changes. This snapshot keeps
every version, so reports can use the values that were true at a given time.
It reads `stg_core_banking__accounts`, so the history has the cleaned column names.
For example: revenue by plan type in March must use the plan that each account had in March,
not the plan it has today.

### Changes it tracks
A new version starts when one of these columns changes:

| Column | Why it is tracked |
|---|---|
| `plan_type` | Plan upgrades and downgrades. Needed for revenue, pricing and churn analysis by plan at a point in time. |
| `industry` | The customer segment can be corrected or updated. Needed so that segment reports for past periods do not change after the fact. |


### How it works
- **Strategy `check`:** at each run, dbt compares the tracked columns with the current version.
- **Runs after every load:** the snapshot runs in the `dwh_snapshots` Airflow DAG, after the
  staging models are built. If a value changes twice between 2 runs, only the last value is kept.
- **Deleted accounts:** if an account disappears from the source, its current version is closed
  (`dbt_valid_to` is set to the time of the run). No row is removed.

### How to use it
- Current version of each account: `where dbt_valid_to = '9999-12-31'`.
- Version valid at time T: `where dbt_valid_from <= T and T < dbt_valid_to`.
- Full history of one account: `where account_id = '...' order by dbt_valid_from`.

{% enddocs %}


{% docs snp_core_banking__virtual_cards %}
History of virtual cards (slowly changing dimension, type 2).
One row per card and version.

### Why this snapshot exists
The source table `core_banking.virtual_cards` is overwritten on every load. It only shows the
current state of each card. Without history, a transaction made on a card that is now
BLOCKED or CANCELLED cannot be checked against the status the card had **when the
transaction happened**. This snapshot keeps every version of the card.
It reads `stg_core_banking__virtual_cards`, so the history has the cleaned column names.

### Changes it tracks
A new version starts when one of these columns changes:

| Column | Why it is tracked |
|---|---|
| `card_status` | The card lifecycle: PENDING → ACTIVE → BLOCKED → CANCELLED. Needed to find transactions on blocked or cancelled cards (risk and fraud checks), to measure how long cards stay active, and to count active cards on a past date. |
| `card_type` | The type can change (for example VIRTUAL → INSTANT). Needed so that card and spend reports for past periods use the type that was valid at that time. |


### How it works
- **Strategy `check`:** at each run, dbt compares the tracked columns with the current version.
- **Runs after every load:** the snapshot runs in the `dwh_snapshots` Airflow DAG, after the
  staging models are built. If the status changes twice between 2 runs (for example ACTIVE →
  BLOCKED → ACTIVE), the change is not recorded.
- **Deleted cards:** if a card disappears from the source, its current version is closed
  (`dbt_valid_to` is set to the time of the run). No row is removed.

### How to use it
- Current version of each card: `where dbt_valid_to = '9999-12-31'`.
- Status of a card when a transaction happened:
  `t.transaction_at >= c.dbt_valid_from and t.transaction_at < c.dbt_valid_to`.
- Full history of one card: `where card_id = '...' order by dbt_valid_from`.

### Limitation
`dbt_valid_from` is the time of the snapshot run that first saw the change, not the exact time
the status changed in the source. With daily runs, a status change is known to within 1 day.
The first version of each card starts at the first snapshot run, not at `created_at`.

{% enddocs %}
