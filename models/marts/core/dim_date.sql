-- One row per day, from the first account creation date to today.
-- Lets time series show days and months with no activity as 0.
with

bounds as (

    select
        min(cast(created_at as date)) as first_date,
        current_date                  as last_date

    from {{ ref('stg_core_banking__accounts') }}

),

days as (

    select cast(unnest(generate_series(first_date, last_date, interval 1 day)) as date) as date_day
    from bounds

),

final as (

    select
        -- dates
        date_day,
        cast(date_trunc('week', date_day) as date)  as week_start_date,
        cast(date_trunc('month', date_day) as date) as month_start_date,

        -- numerics
        extract(year from date_day)    as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day)   as month_number,
        isodow(date_day)               as day_of_week_number,

        -- strings
        monthname(date_day)            as month_name,
        dayname(date_day)              as day_name,

        -- booleans
        isodow(date_day) in (6, 7)     as is_weekend

    from days

)

select * from final
