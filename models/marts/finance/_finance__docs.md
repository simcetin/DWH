{# ---------- mart_spending_patterns_daily ---------- #}

{% docs mart_spending_patterns_daily %}
Card spending per calendar day, business segment and merchant category, in EUR.
Owned by the Finance team.
One row per day (every day in `dim_date`), per industry and plan combination that exists in the
account history, and per merchant category. Days without transactions show 0.
Answers: what spending patterns look like, for payment volume and revenue reporting.

- Only transactions made while the card was ACTIVE count (from `fct_card_transactions`).
- `industry` and `plan_type` are the account's values **at the time of the transaction**.
- Refunds are included with their negative amount, so `transaction_amount_eur` is **net** spend.

Both measures can be summed across days and segments.
{% enddocs %}

{% docs mart_spending_patterns_daily__transaction_count %}
Number of transactions, purchases and refunds together.
Business owner of this definition: Finance team.
{% enddocs %}

{% docs mart_spending_patterns_daily__transaction_amount_eur %}
Net amount of the transactions in EUR: purchases minus refunds.
Business owner of this definition: Finance team.
{% enddocs %}
