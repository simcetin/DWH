-- History of virtual cards. One row per card and version (SCD type 2).
-- Only card_status and card_type can change, so the snapshot tracks those columns
-- and the other columns stay correct on every version.
--
-- The first version starts at card creation, not at the first snapshot run, so
-- that every date since creation finds a version. Assumption: the first known
-- status and type were valid since creation (no earlier history exists).
{{ config(tags=['core']) }}

with

card_versions as (

    select
        -- ids
        dbt_scd_id     as card_history_id,
        card_id,
        account_id,

        -- strings
        card_name,
        card_status,
        card_type,

        -- booleans
        card_status = 'ACTIVE'                          as is_activated,
        dbt_valid_to = cast('9999-12-31' as timestamp) as is_current,

        -- timestamps
        created_at     as card_created_at,
        case
            when row_number() over (partition by card_id order by dbt_valid_from) = 1
                then least(created_at, dbt_valid_from)
            else dbt_valid_from
        end            as valid_from,
        dbt_valid_to   as valid_to

    from {{ ref('snp_core_banking__virtual_cards') }}

)

select * from card_versions
