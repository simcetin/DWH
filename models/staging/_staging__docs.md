{# Doc blocks for technical columns that dbt adds to models. #}

{% docs _dbt_loaded_at %}
When dbt wrote the row to this model (with time zone). Later incremental models use it
to read only the rows that changed in this model since their last run.
{% enddocs %}
