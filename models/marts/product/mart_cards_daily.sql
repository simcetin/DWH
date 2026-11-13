-- Cards created and cards used per calendar day and business segment.
-- One row per day (every day in dim_date) and per industry, plan and country
-- combination that exists in the account history. Days without activity show 0.
-- Both counts come from fct_card_usage_daily, with the account segment of that day.
--
-- cards_used cannot be summed across days: a card used on 3 days counts 3 times.
-- For used cards over a longer period, count distinct card_id in fct_card_usage_daily.
{{ config(tags=['product']) }}

with

dates as (

    select date_day
    from {{ ref('dim_date') }}

),

segments as (

    select distinct
        industry,
        plan_type,
        country_code

    from {{ ref('dim_accounts_history') }}

),

-- Every day for every segment combination.
spine as (

    select
        dates.date_day,
        segments.industry,
        segments.plan_type,
        segments.country_code

    from dates
    cross join segments

),

-- One row per card and day.
daily_cards as (

    select
        date_day,
        industry,
        plan_type,
        country_code,
        sum(case when is_creation_day then 1 else 0 end) as cards_created,
        sum(case when is_used then 1 else 0 end)         as cards_used

    from {{ ref('fct_card_usage_daily') }}
    group by date_day, industry, plan_type, country_code

),

final as (

    select
        -- dates
        spine.date_day,

        -- strings
        spine.industry,
        spine.plan_type,
        spine.country_code,

        -- numerics
        coalesce(daily_cards.cards_created, 0) as cards_created,
        coalesce(daily_cards.cards_used, 0)    as cards_used

    from spine
    left join daily_cards
        on  daily_cards.date_day = spine.date_day
        and daily_cards.industry = spine.industry
        and daily_cards.plan_type = spine.plan_type
        and daily_cards.country_code = spine.country_code

)

select * from final
