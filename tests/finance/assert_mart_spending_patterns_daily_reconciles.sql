{{
    config(
        tags=['finance'],
        meta={'owner': 'finance-analytics'}
    )
}}

-- mart_spending_patterns_daily must contain every transaction of fct_card_transactions:
-- the same number of transactions and the same net amount. A difference means a
-- transaction did not match a day, segment or merchant category of the spine.
with

mart_totals as (

    select
        sum(transaction_count)      as transaction_count,
        sum(transaction_amount_eur) as transaction_amount_eur

    from {{ ref('mart_spending_patterns_daily') }}

),

fact_totals as (

    select
        count(*)        as transaction_count,
        sum(amount_eur) as transaction_amount_eur

    from {{ ref('fct_card_transactions') }}

)

select *
from mart_totals
cross join fact_totals
where mart_totals.transaction_count <> fact_totals.transaction_count
   or mart_totals.transaction_amount_eur <> fact_totals.transaction_amount_eur
