-- Current state of each customer account. One row per account.
{{ config(tags=['core']) }}

with

accounts as (

    select
        -- ids
        account_id,

        -- strings
        company_name,
        industry,
        country_code,
        plan_type,

        -- timestamps
        created_at as account_created_at

    from {{ ref('stg_core_banking__accounts') }}

)

select * from accounts
