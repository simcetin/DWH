{{
    config(
        tags=['product'],
        meta={'owner': 'product-analytics'}
    )
}}

-- mart_card_activation_monthly must not lose or invent cards:
--   total new_cards_created        = number of cards in dim_virtual_cards
--   total_cards of the last month  = number of cards in dim_virtual_cards
--   total cards_used               = number of different card and month pairs with usage
-- It also checks every month: total_active_cards is not more than total_cards, and
-- activation_rate is between 0 and 1.
with

mart_totals as (

    select
        sum(new_cards_created) as new_cards_created,
        max(total_cards)   as last_month_total_cards,
        sum(cards_used)    as cards_used,
        sum(case when total_active_cards > total_cards
                   or activation_rate < 0 or activation_rate > 1 then 1 else 0 end) as invalid_months

    from {{ ref('mart_card_activation_monthly') }}

),

card_totals as (

    select count(*) as cards
    from {{ ref('dim_virtual_cards') }}

),

usage_totals as (

    select count(*) as cards_used
    from (
        select distinct
            card_id,
            date_trunc('month', date_day) as usage_month
        from {{ ref('fct_card_usage_daily') }}
        where is_used
    ) as card_months

)

select *
from mart_totals
cross join card_totals
cross join usage_totals
where mart_totals.new_cards_created <> card_totals.cards
   or mart_totals.last_month_total_cards <> card_totals.cards
   or mart_totals.cards_used <> usage_totals.cards_used
   or mart_totals.invalid_months > 0
