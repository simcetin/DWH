{% docs ecb %}
Euro foreign exchange reference rates from the European Central Bank (ECB).
In this project the table is
loaded from `seeds/ecb`, which has a rate for every day.
{% enddocs %}


{# ---------- Tables ---------- #}

{% docs stg_ecb__fx_rate %}
One row per day and currency.
{% enddocs %}


{# ---------- Columns ---------- #}

{% docs stg_ecb__fx_rate__fx_rate_id %}
Unique ID of an FX rate, built from `rate_date` and `currency_code` (for example `2026-01-01-USD`).
{% enddocs %}

{% docs stg_ecb__fx_rate__eur_rate %}
Units of the currency per 1 EUR. To convert an amount to EUR, use `amount / eur_rate`.
The rate for EUR is always 1.
{% enddocs %}

{% docs stg_ecb__fx_rate__rate_date %}
Day the rate applies to.
{% enddocs %}

{% docs stg_ecb__fx_rate__currency_code %}
Three-letter ISO 4217 currency code.

| Value |
|---|
| EUR |
| USD |
| GBP |
| CHF |
| PLN |
| SEK |
| DKK |
{% enddocs %}
