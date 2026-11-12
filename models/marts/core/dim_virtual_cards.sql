-- Current state of each virtual card. One row per card.
-- Activation definition (Product team): a card is activated when its current
-- status is ACTIVE.
with

cards as (

    select
        -- ids
        card_id,
        account_id,

        -- strings
        card_name,
        card_status,
        card_type,

        -- booleans
        card_status = 'ACTIVE' as is_activated,

        -- timestamps
        created_at as card_created_at

    from {{ ref('stg_core_banking__virtual_cards') }}

)

select * from cards
