{{
    config(
        tags=['core'],
        meta={'owner': 'analytics-engineering'}
    )
}}

-- fct_card_usage_daily must contain every purchase transaction of fct_card_transactions.
-- A difference means a purchase fell on a day without a card row (for example,
-- before the card's creation date).
with

usage_totals as (

    select
        sum(transaction_count)      as transaction_count,
        sum(transaction_amount_eur) as transaction_amount_eur

    from {{ ref('fct_card_usage_daily') }}

),

transaction_totals as (

    select
        count(*)        as transaction_count,
        sum(amount_eur) as transaction_amount_eur

    from {{ ref('fct_card_transactions') }}
    where not is_refund

)

select *
from usage_totals
cross join transaction_totals
where usage_totals.transaction_count <> transaction_totals.transaction_count
   or usage_totals.transaction_amount_eur <> transaction_totals.transaction_amount_eur
