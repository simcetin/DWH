{# Doc blocks for technical columns that dbt adds to models. #}

{% docs _dbt_loaded_at %}
When dbt wrote the row to `stg_core_banking__transactions` (with time zone). Downstream models
keep this value, and incremental models use it to read only the rows that changed since their
last run.
{% enddocs %}
