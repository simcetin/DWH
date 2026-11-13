{{
    config(
        severity='warn',
        group='core',
        tags=['core'],
        meta={'owner': 'analytics-engineering'}
    )
}}

-- Transactions that fct_card_transactions excludes, with the reason:
--   no_card_version:     no card version valid at the transaction time
--                        (for example, before the card was created)
--   card_not_active:     the card was PENDING, BLOCKED or CANCELLED at that time
--   no_account_version:  no account version valid at the transaction time
-- Warning only: the fact stays correct, but excluded transactions should stay visible.
with

transactions as (

    select
        transaction_id,
        card_id,
        transaction_at

    from {{ ref('int_transactions_converted_to_eur') }}

),

card_versions as (

    select
        card_id,
        account_id,
        card_status,
        card_created_at,
        valid_from,
        valid_to

    from {{ ref('dim_virtual_cards_history') }}

),

account_versions as (

    select
        account_id,
        valid_from,
        valid_to

    from {{ ref('dim_accounts_history') }}

),

checked as (

    select
        transactions.transaction_id,
        transactions.card_id,
        transactions.transaction_at,
        card_versions.card_status,
        case
            when card_versions.card_id is null
              or transactions.transaction_at < card_versions.card_created_at then 'no_card_version'
            when card_versions.card_status <> 'ACTIVE'                         then 'card_not_active'
            when account_versions.account_id is null                          then 'no_account_version'
        end as exclusion_reason

    from transactions
    left join card_versions
        on  card_versions.card_id = transactions.card_id
        and transactions.transaction_at >= card_versions.valid_from
        and transactions.transaction_at < card_versions.valid_to
    left join account_versions
        on  account_versions.account_id = card_versions.account_id
        and transactions.transaction_at >= account_versions.valid_from
        and transactions.transaction_at < account_versions.valid_to

)

select * from checked
where exclusion_reason is not null
