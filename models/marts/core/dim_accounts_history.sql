-- History of customer accounts. One row per account and version (SCD type 2).
-- Only industry and plan_type can change, so the snapshot tracks those columns and
-- the other columns stay correct on every version.
-- (Checked by tests/marts/assert_untracked_columns_do_not_change.sql.)
--
-- The first version starts at account creation, not at the first snapshot run, so
-- that every date since creation finds a version. Assumption: the first known
-- industry and plan were valid since creation (no earlier history exists).
{{ config(tags=['core']) }}

with

account_versions as (

    select
        -- ids
        dbt_scd_id     as account_history_id,
        account_id,

        -- strings
        company_name,
        industry,
        country        as country_code,
        plan_type,

        -- booleans
        dbt_valid_to = cast('9999-12-31' as timestamp) as is_current,

        -- timestamps
        created_at     as account_created_at,
        case
            when row_number() over (partition by account_id order by dbt_valid_from) = 1
                then least(created_at, dbt_valid_from)
            else dbt_valid_from
        end            as valid_from,
        dbt_valid_to   as valid_to

    from {{ ref('snp_core_banking__accounts') }}

)

select * from account_versions
