{# ---------- int_transactions_converted_to_eur ---------- #}

{% docs int_transactions_converted_to_eur %}
One row per card transaction, with the amount converted to EUR.
Joins the transactions (core banking) with the ECB rate of the transaction day and currency.
This is the only place where the EUR conversion rule is defined.
{% enddocs %}

{% docs int_transactions_converted_to_eur__amount_eur %}
Amount in EUR: `amount / eur_rate`, using the ECB rate of the transaction day, rounded to
2 decimals. Negative amounts are refunds.
Business owner of this rule: Finance team.
{% enddocs %}
