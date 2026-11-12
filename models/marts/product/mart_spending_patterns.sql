-- Spending by transaction month, business segment and merchant category, in EUR.
-- One row per transaction month, industry, country, plan and merchant category.
-- spending_cards and spending_accounts are distinct counts: they cannot be summed
-- across rows.
with

transactions as (

    select
        transaction_id,
        card_id,
        account_id,
        merchant_category,
        amount_eur,
        is_refund,
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

aggregated as (

    select
        -- dates
        cast(date_trunc('month', transactions.transaction_date) as date) as transaction_month,

        -- strings
        accounts.industry,
        accounts.country_code,
        accounts.plan_type,
        transactions.merchant_category,

        -- numerics
        count(*)                                                             as transaction_count,
        count(*) filter (where not transactions.is_refund)                   as purchase_count,
        count(*) filter (where transactions.is_refund)                       as refund_count,
        coalesce(sum(transactions.amount_eur) filter (where not transactions.is_refund), 0) as gross_spend_eur,
        coalesce(-sum(transactions.amount_eur) filter (where transactions.is_refund), 0)    as refund_amount_eur,
        sum(transactions.amount_eur)                                         as net_spend_eur,
        count(distinct transactions.card_id)                                 as spending_cards,
        count(distinct transactions.account_id)                              as spending_accounts

    from transactions
    left join accounts
        on accounts.account_id = transactions.account_id
    group by 1, 2, 3, 4, 5

),

final as (

    select
        transaction_month,
        industry,
        country_code,
        plan_type,
        merchant_category,
        transaction_count,
        purchase_count,
        refund_count,
        gross_spend_eur,
        refund_amount_eur,
        net_spend_eur,
        round(gross_spend_eur / nullif(purchase_count, 0), 2) as avg_purchase_eur,
        spending_cards,
        spending_accounts

    from aggregated

)

select * from final
