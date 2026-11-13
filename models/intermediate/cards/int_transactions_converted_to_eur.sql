-- Adds the EUR amount to each transaction, using the ECB rate of the transaction day.
-- Left join: a transaction without a rate keeps a null amount_eur, which the
-- not_null test on amount_eur reports, instead of being silently dropped.
{{ config(tags=['core']) }}

with

transactions as (

    select
        transaction_id,
        card_id,
        merchant_category,
        currency_code,
        amount,
        is_refund,
        transaction_date,
        transaction_at,
        _dbt_loaded_at

    from {{ ref('stg_core_banking__transactions') }}

),

fx_rates as (

    select
        currency_code,
        rate_date,
        eur_rate

    from {{ ref('stg_ecb__fx_rate') }}

),

converted as (

    select
        -- ids
        transactions.transaction_id,
        transactions.card_id,

        -- strings
        transactions.merchant_category,
        transactions.currency_code,

        -- numerics
        transactions.amount,
        fx_rates.eur_rate,
        cast(round(transactions.amount / fx_rates.eur_rate, 2) as decimal(18, 2)) as amount_eur,

        -- booleans
        transactions.is_refund,

        -- dates
        transactions.transaction_date,

        -- timestamps
        transactions.transaction_at,

        -- metadata
        transactions._dbt_loaded_at

    from transactions
    left join fx_rates
        on  fx_rates.currency_code = transactions.currency_code
        and fx_rates.rate_date = transactions.transaction_date

)

select * from converted
