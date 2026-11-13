-- Card activation and usage per month. One row per month, from the month of the
-- first card creation to the current month. Months without activity show 0.
--
--   new_cards_created: new cards created in that month.
--   total_cards: all cards created up to the end of that month.
--   total_active_cards: of all those cards, the cards whose status was ACTIVE at the
--     end of that month, from dim_virtual_cards_history. For the current month, the
--     latest status so far. A card can be active in one month and blocked in the next.
--   activation_rate: total_active_cards / total_cards.
--   cards_used: different cards with at least 1 purchase in that month, made while
--     the card was ACTIVE. Each card counts once per month.
--

{{ config(tags=['product']) }}

with

months as (

    select distinct
        month_start_date,
        {{ dbt.dateadd('month', 1, 'month_start_date') }} as next_month_start_date

    from {{ ref('dim_date') }}

),

card_history as (

    select
        card_id,
        is_activated,
        card_created_at,
        valid_from,
        valid_to

    from {{ ref('dim_virtual_cards_history') }}

),

card_usage as (

    select
        card_id,
        date_day

    from {{ ref('fct_card_usage_daily') }}
    where is_used

),

-- One row per card and month: the card version that was valid at the end of the month.
-- A version is valid at the end of the month when its period covers the first moment
-- of the next month. The first version of each card starts at its creation, so a card
-- has a row for every month from its creation month on.
-- Example: a card created on 2026-10-19 and blocked on 2026-11-13 is ACTIVE at the
-- end of October (2026-11-01) and BLOCKED at the end of November (its latest status),
-- so it counts as active in October and not active in November.
card_status_at_month_end as (

    select
        months.month_start_date,
        card_history.card_id,
        card_history.is_activated,
        card_history.card_created_at >= months.month_start_date as is_created_this_month

    from months
    inner join card_history
        on  card_history.valid_from < months.next_month_start_date
        and card_history.valid_to >= months.next_month_start_date

),

-- Per month: new cards, all cards so far, and the cards active at the end of the month.
monthly_cards as (

    select
        month_start_date,
        sum(case when is_created_this_month then 1 else 0 end) as new_cards_created,
        count(*)                                               as total_cards,
        sum(case when is_activated then 1 else 0 end)          as total_active_cards

    from card_status_at_month_end
    group by month_start_date

),

-- Different cards used per month.
monthly_used as (

    select
        cast(date_trunc('month', date_day) as date) as month_start_date,
        count(distinct card_id)                     as cards_used

    from card_usage
    group by 1

),

final as (

    select
        -- strings
        strftime(monthly_cards.month_start_date, '%Y-%m')  as year_month,

        -- numerics
        monthly_cards.new_cards_created,
        monthly_cards.total_cards,
        monthly_cards.total_active_cards,
        round(
            monthly_cards.total_active_cards / monthly_cards.total_cards, 4
        )                                                   as activation_rate,
        coalesce(monthly_used.cards_used, 0)                as cards_used,

        -- dates
        monthly_cards.month_start_date

    from monthly_cards
    left join monthly_used
        on monthly_used.month_start_date = monthly_cards.month_start_date

)

select * from final
