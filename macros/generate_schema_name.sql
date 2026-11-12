-- Decides the schema of each dbt object.
--
--   Seeds (raw data):  the custom schema as is, in every target (for example
--                      "raw_core_banking"). Seeds stand in for an ingestion tool,
--                      and the sources point to these exact schema names.
--   Models in prod:    the custom schema as is (for example "staging").
--   Models in dev:     "<target schema>_<custom schema>" (for example
--                      "main_staging"), so development never overwrites prod.
--   No custom schema:  the target schema.
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif node.resource_type == 'seed' or target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
