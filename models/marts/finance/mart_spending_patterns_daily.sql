-- Spending per calendar day, business segment and merchant category, in EUR.
-- One row per day (every day in dim_date) and per industry and plan combination
-- that exists in the account history and per merchant category. Days without
-- transactions show 0.
--
-- Only transactions made while the card was ACTIVE (fct_card_transactions).
-- Industry and plan are the values at the time of the transaction.
-- Refunds are included with their negative amount, so the amount is net spend.
{{ config(tags=['finance']) }}

with

dates as (

    select date_day
    from {{ ref('dim_date') }}

),

segments as (

    select distinct
        industry,
        plan_type

    from {{ ref('dim_accounts_history') }}

),

merchant_categories as (

    select distinct merchant_category
    from {{ ref('fct_card_transactions') }}

),

-- Every day for every segment and merchant category.
spine as (

    select
        dates.date_day,
        segments.industry,
        segments.plan_type,
        merchant_categories.merchant_category

    from dates
    cross join segments
    cross join merchant_categories

),

daily_spending as (

    select
        transaction_date  as date_day,
        industry,
        plan_type,
        merchant_category,
        count(*)          as transaction_count,
        sum(amount_eur)   as transaction_amount_eur

    from {{ ref('fct_card_transactions') }}
    group by transaction_date, industry, plan_type, merchant_category

),

final as (

    select
        -- dates
        spine.date_day,

        -- strings
        spine.industry,
        spine.plan_type,
        spine.merchant_category,

        -- numerics
        coalesce(daily_spending.transaction_count, 0)      as transaction_count,
        coalesce(daily_spending.transaction_amount_eur, 0) as transaction_amount_eur

    from spine
    left join daily_spending
        on  daily_spending.date_day = spine.date_day
        and daily_spending.industry = spine.industry
        and daily_spending.plan_type = spine.plan_type
        and daily_spending.merchant_category = spine.merchant_category

)

select * from final
