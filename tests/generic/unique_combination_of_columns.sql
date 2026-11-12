-- Fails when the combination of the given columns is not unique.
-- Used to test the grain of aggregated models (without the dbt_utils package).
{% test unique_combination_of_columns(model, combination_of_columns) %}

select
    {{ combination_of_columns | join(', ') }},
    count(*) as row_count
from {{ model }}
group by {{ combination_of_columns | join(', ') }}
having count(*) > 1

{% endtest %}
