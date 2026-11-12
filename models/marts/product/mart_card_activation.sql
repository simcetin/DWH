-- Card creation, activation and usage by creation month and business segment.
-- One row per creation month, industry, country, plan and card type.
--   activation_rate = activated cards / cards created
--   usage_rate      = activated cards with at least 1 transaction / activated cards
-- Rates cannot be summed or averaged across rows. To combine rows, sum the counts
-- and divide again.
with

cards as (

    select
        card_id,
        account_id,
        card_type,
        is_activated,
        card_created_at

    from {{ ref('dim_virtual_cards') }}

),

-- Cards with at least 1 counted transaction (made while the card was ACTIVE).
cards_with_transactions as (

    select distinct card_id
    from {{ ref('fct_card_transactions') }}

),

accounts as (

    select
        account_id,
        industry,
        country_code,
        plan_type

    from {{ ref('dim_accounts') }}

),

aggregated as (

    select
        -- dates
        cast(date_trunc('month', cards.card_created_at) as date) as created_month,

        -- strings
        accounts.industry,
        accounts.country_code,
        accounts.plan_type,
        cards.card_type,

        -- numerics
        count(*)                                                                   as cards_created,
        count(*) filter (where cards.is_activated)                                 as activated_cards,
        count(cards_with_transactions.card_id)                                     as cards_with_transactions,
        count(cards_with_transactions.card_id)
            filter (where cards.is_activated)                                      as activated_cards_with_transactions

    from cards
    left join accounts
        on accounts.account_id = cards.account_id
    left join cards_with_transactions
        on cards_with_transactions.card_id = cards.card_id
    group by 1, 2, 3, 4, 5

),

final as (

    select
        created_month,
        industry,
        country_code,
        plan_type,
        card_type,
        cards_created,
        activated_cards,
        cards_with_transactions,
        activated_cards_with_transactions,
        round(activated_cards / cards_created, 4)                                 as activation_rate,
        round(activated_cards_with_transactions / nullif(activated_cards, 0), 4)  as usage_rate

    from aggregated

)

select * from final
