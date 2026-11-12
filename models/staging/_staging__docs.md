{# Doc blocks for columns that more than one source system has. #}

{% docs currency_code %}
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

{% docs _dbt_loaded_at %}
When dbt wrote the row to this model (with time zone). Later incremental models use it
to read only the rows that changed in this model since their last run.
{% enddocs %}
