-- One row per virtual card and day, from the day the card was created until today.
-- Every card is included, used or not. is_used flags the days with usage.
--
-- Usage definition (Product team): a card is used in a period when it has at least
-- 1 purchase in that period, made while the card was ACTIVE. Purchases are
-- transactions with a positive amount; refunds do not count as usage.
--
-- Card and account attributes are the versions valid at the end of each day.
--
-- Incremental: each run rebuilds the last 3 days for all cards (rows replaced by
-- card_id + date_day). This covers new days, late transactions up to 3 days old and
-- recent card or account changes. Run a full refresh regularly (for example weekly)
-- to correct anything older.
{{
    config(
        tags=['core'],
        materialized='incremental',
        unique_key=['card_id', 'date_day'],
        incremental_strategy='delete+insert',
        on_schema_change='append_new_columns'
    )
}}

with

dates as (

    select date_day
    from {{ ref('dim_date') }}

),

cards as (

    select
        card_id,
        account_id,
        card_created_at

    from {{ ref('dim_virtual_cards') }}

),

-- Every day of every card, from its creation date until today
-- (on incremental runs: only the last 3 days).
card_days as (

    select
        cards.card_id,
        cards.account_id,
        dates.date_day,
        cast(cards.card_created_at as date)           as card_created_date,
        {{ dbt.dateadd('day', 1, 'dates.date_day') }} as day_end

    from cards
    inner join dates
        on dates.date_day >= cast(cards.card_created_at as date)

    {% if is_incremental() %}
    -- Only the last 3 days.
    where dates.date_day >= {{ dbt.dateadd('day', -3, '(select max(date_day) from ' ~ this ~ ')') }}
    {% endif %}

),

card_versions as (

    select
        card_id,
        card_status,
        card_type,
        valid_from,
        valid_to

    from {{ ref('dim_virtual_cards_history') }}

),

account_versions as (

    select
        account_id,
        industry,
        country_code,
        plan_type,
        valid_from,
        valid_to

    from {{ ref('dim_accounts_history') }}

),

-- Purchase transactions per card and day (refunds excluded).
-- fct_card_transactions only has ACTIVE-card transactions.
daily_transactions as (

    select
        card_id,
        transaction_date,
        count(*)        as transaction_count,
        sum(amount_eur) as transaction_amount_eur

    from {{ ref('fct_card_transactions') }}
    where not is_refund
    group by card_id, transaction_date

),

final as (

    select
        -- ids
        card_days.card_id,
        card_days.account_id,

        -- strings (versions valid at the end of the day)
        card_versions.card_status,
        card_versions.card_type,
        account_versions.industry,
        account_versions.country_code,
        account_versions.plan_type,

        -- numerics
        coalesce(daily_transactions.transaction_count, 0)      as transaction_count,
        coalesce(daily_transactions.transaction_amount_eur, 0) as transaction_amount_eur,

        -- booleans
        card_days.date_day = card_days.card_created_date    as is_creation_day,
        daily_transactions.card_id is not null              as is_used,

        -- dates
        card_days.date_day,

        -- metadata
        current_timestamp                                as _dbt_loaded_at

    from card_days
    -- The version valid at the end of the day (the last version that started that day or before).
    left join card_versions
        on  card_versions.card_id = card_days.card_id
        and card_versions.valid_from < card_days.day_end
        and card_versions.valid_to >= card_days.day_end
    left join account_versions
        on  account_versions.account_id = card_days.account_id
        and account_versions.valid_from < card_days.day_end
        and account_versions.valid_to >= card_days.day_end
    left join daily_transactions
        on  daily_transactions.card_id = card_days.card_id
        and daily_transactions.transaction_date = card_days.date_day

)

select * from final
