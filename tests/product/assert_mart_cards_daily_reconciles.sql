{{
    config(
        tags=['product'],
        meta={'owner': 'product-analytics'}
    )
}}

-- mart_cards_daily must not lose cards or usage days:
--   total cards_created = number of cards in dim_virtual_cards
--   total cards_used    = number of used card-days in fct_card_usage_daily
-- A difference means a card-day did not match a segment combination of the spine.
with

mart_totals as (

    select
        sum(cards_created) as cards_created,
        sum(cards_used)    as cards_used

    from {{ ref('mart_cards_daily') }}

),

expected as (

    select
        (select count(*) from {{ ref('dim_virtual_cards') }})                   as cards_created,
        (select count(*) from {{ ref('fct_card_usage_daily') }} where is_used) as cards_used

)

select
    mart_totals.cards_created as mart_cards_created,
    expected.cards_created    as expected_cards_created,
    mart_totals.cards_used    as mart_cards_used,
    expected.cards_used       as expected_cards_used

from mart_totals
cross join expected
where mart_totals.cards_created <> expected.cards_created
   or mart_totals.cards_used <> expected.cards_used
