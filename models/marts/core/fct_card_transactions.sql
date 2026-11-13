-- One row per card transaction, with the amount in EUR and the card and account
-- attributes as they were when the transaction happened (from the history dims).
-- A transaction counts only if the card was ACTIVE when it happened and its account
-- had a valid version at that time. Other transactions (before card creation, card
-- PENDING, BLOCKED or CANCELLED, no account version) are excluded. They are counted
-- by the warning test
-- tests/marts/warn_transactions_excluded_from_fact.sql.
--
-- Incremental: each run reads only the rows that dbt wrote to staging since the
-- last run (_dbt_loaded_at). Rows with an existing transaction_id are replaced.
{{
    config(
        tags=['core'],
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='delete+insert',
        on_schema_change='append_new_columns'
    )
}}

with

transactions as (

    select
        transaction_id,
        card_id,
        merchant_category,
        currency_code,
        amount,
        eur_rate,
        amount_eur,
        is_refund,
        transaction_date,
        transaction_at,
        _dbt_loaded_at as source_loaded_at

    from {{ ref('int_transactions_converted_to_eur') }}

    {% if is_incremental() %}
    where source_loaded_at > (select max(_dbt_loaded_at) from {{ this }})
    {% endif %}

),

card_versions as (

    select
        card_id,
        account_id,
        card_name,
        card_status,
        card_type,
        card_created_at,
        valid_from,
        valid_to

    from {{ ref('dim_virtual_cards_history') }}

),

account_versions as (

    select
        account_id,
        company_name,
        industry,
        country_code,
        plan_type,
        account_created_at,
        valid_from,
        valid_to

    from {{ ref('dim_accounts_history') }}

),

final as (

    select
        -- ids
        transactions.transaction_id,
        transactions.card_id,
        card_versions.account_id,

        -- strings: transaction
        transactions.merchant_category,
        transactions.currency_code,

        -- strings: card at transaction time
        card_versions.card_name,
        card_versions.card_type,

        -- strings: account at transaction time
        account_versions.company_name,
        account_versions.industry,
        account_versions.country_code,
        account_versions.plan_type,

        -- numerics
        transactions.amount,
        transactions.eur_rate,
        transactions.amount_eur,

        -- booleans
        transactions.is_refund,

        -- dates
        transactions.transaction_date,

        -- timestamps
        transactions.transaction_at,
        account_versions.account_created_at,

        -- metadata
        current_timestamp as _dbt_loaded_at

    from transactions
    -- The card and account versions valid at the transaction time. 
    -- Inner joins: a transaction counts only if both the card and its account have a
    -- valid version at the transaction time.
    inner join card_versions
        on  card_versions.card_id = transactions.card_id
        and transactions.transaction_at >= card_versions.valid_from
        and transactions.transaction_at < card_versions.valid_to
    inner join account_versions
        on  account_versions.account_id = card_versions.account_id
        and transactions.transaction_at >= account_versions.valid_from
        and transactions.transaction_at < account_versions.valid_to
    -- Only transactions made while the card was ACTIVE.
    where transactions.transaction_at >= card_versions.card_created_at
      and card_versions.card_status = 'ACTIVE'

)

select * from final
