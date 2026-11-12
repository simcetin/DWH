-- Cards created per day, with a running total. One row per day, from the first
-- card creation to today. Days without new cards show 0.
with

dates as (

    select
        date_day,
        month_start_date

    from {{ ref('dim_date') }}

),

card_creations as (

    select
        card_id,
        cast(card_created_at as date) as card_created_date

    from {{ ref('dim_virtual_cards') }}

),

daily_creations as (

    select
        card_created_date,
        count(*) as cards_created

    from card_creations
    group by card_created_date

),

final as (

    select
        -- dates
        dates.date_day,
        dates.month_start_date,

        -- numerics
        coalesce(daily_creations.cards_created, 0) as cards_created,
        sum(coalesce(daily_creations.cards_created, 0))
            over (order by dates.date_day)         as cumulative_cards_created

    from dates
    left join daily_creations
        on daily_creations.card_created_date = dates.date_day
    where dates.date_day >= (select min(card_created_date) from card_creations)

)

select * from final
