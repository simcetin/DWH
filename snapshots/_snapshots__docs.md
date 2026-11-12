{# Doc blocks for the columns that dbt adds to every snapshot. #}

{% docs dbt_scd_id %}
Unique ID of one version of a row. Built by dbt.
{% enddocs %}

{% docs dbt_updated_at %}
When dbt recorded this version.
{% enddocs %}

{% docs dbt_valid_from %}
Start of the period when this version was valid (the snapshot run that first saw it).
{% enddocs %}

{% docs dbt_valid_to %}
End of the period when this version was valid. 9999-12-31 means it is the current version.
To find the version valid at a time T: `dbt_valid_from <= T and T < dbt_valid_to`.
{% enddocs %}
