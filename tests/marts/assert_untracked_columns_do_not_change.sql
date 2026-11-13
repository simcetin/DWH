{{
    config(
        group='core',
        tags=['core'],
        meta={'owner': 'analytics-engineering'}
    )
}}

-- The history dims assume that only the snapshot's check_cols can change:
--   accounts: industry, plan_type        cards: status, card_type
-- The snapshot does not update other columns. If one of them changes in the
-- source anyway, the history would show an old value. This test fails when the
-- current version differs from staging in a column that should never change.
with

account_differences as (

    select
        'account' as entity,
        history.account_id as entity_id
    from {{ ref('dim_accounts_history') }} as history
    inner join {{ ref('stg_core_banking__accounts') }} as current_accounts
        on current_accounts.account_id = history.account_id
    where history.is_current
      and (   history.company_name       is distinct from current_accounts.company_name
           or history.country_code       is distinct from current_accounts.country_code
           or history.account_created_at is distinct from current_accounts.created_at)

),

card_differences as (

    select
        'card' as entity,
        history.card_id as entity_id
    from {{ ref('dim_virtual_cards_history') }} as history
    inner join {{ ref('stg_core_banking__virtual_cards') }} as current_cards
        on current_cards.card_id = history.card_id
    where history.is_current
      and (   history.account_id      is distinct from current_cards.account_id
           or history.card_name       is distinct from current_cards.card_name
           or history.card_created_at is distinct from current_cards.created_at)

)

select * from account_differences
union all
select * from card_differences
