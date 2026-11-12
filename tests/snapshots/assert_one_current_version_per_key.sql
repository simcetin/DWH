-- Each account and each card must have exactly one current version
-- (dbt_valid_to = 9999-12-31). Two current versions would double rows in joins.
with

current_versions as (

    select 'account' as entity, account_id as entity_id
    from {{ ref('snp_core_banking__accounts') }}
    where dbt_valid_to = cast('9999-12-31' as timestamp)

    union all

    select 'card' as entity, card_id as entity_id
    from {{ ref('snp_core_banking__virtual_cards') }}
    where dbt_valid_to = cast('9999-12-31' as timestamp)

)

select entity, entity_id, count(*) as current_versions
from current_versions
group by entity, entity_id
having count(*) > 1
