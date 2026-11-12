-- Usage frequency by month and business segment.
-- One row per month, industry, country and plan.
--   active_cards      = activated cards (current status ACTIVE) created before the month ends
--   usage_frequency   = transactions on those cards in the month / active_cards
-- Months run from the first to the last transaction month.
with

months as (

    select distinct month_start_date as activity_month
    from {{ ref('dim_date') }}
    where month_start_date between
        (select cast(date_trunc('month', min(transaction_date)) as date) from {{ ref('fct_card_transactions') }})
        and (select cast(date_trunc('month', max(transaction_date)) as date) from {{ ref('fct_card_transactions') }})

),

activated_cards as (

    select
        card_id,
        account_id,
        card_created_at

    from {{ ref('dim_virtual_cards') }}
    where is_activated

),

transactions as (

    select
        card_id,
        transaction_date

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

-- One row per month and card that already existed in that month.
active_card_months as (

    select
        months.activity_month,
        activated_cards.card_id,
        activated_cards.account_id

    from months
    inner join activated_cards
        on activated_cards.card_created_at < {{ dbt.dateadd('month', 1, 'months.activity_month') }}

),

monthly_card_transactions as (

    select
        cast(date_trunc('month', transaction_date) as date) as activity_month,
        card_id,
        count(*) as transaction_count

    from transactions
    group by 1, 2

),

aggregated as (

    select
        -- dates
        active_card_months.activity_month,

        -- strings
        accounts.industry,
        accounts.country_code,
        accounts.plan_type,

        -- numerics
        count(*)                                                       as active_cards,
        coalesce(sum(monthly_card_transactions.transaction_count), 0)  as transactions_on_active_cards

    from active_card_months
    left join monthly_card_transactions
        on  monthly_card_transactions.activity_month = active_card_months.activity_month
        and monthly_card_transactions.card_id = active_card_months.card_id
    left join accounts
        on accounts.account_id = active_card_months.account_id
    group by 1, 2, 3, 4

),

final as (

    select
        activity_month,
        industry,
        country_code,
        plan_type,
        active_cards,
        transactions_on_active_cards,
        round(transactions_on_active_cards / active_cards, 2) as usage_frequency

    from aggregated

)

select * from final
