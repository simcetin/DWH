-- Incremental because transactions are high volume.
-- Each run reads only the raw rows that the ingestion step loaded since the last run
-- (_loaded_at), plus a 3-hour lookback for late loads. Rows with an existing
-- transaction_id are replaced, so changed transactions do not create duplicates.
{{
    config(
        tags=['core'],
        materialized='incremental',
        unique_key='transaction_id',
        incremental_strategy='delete+insert',
        on_schema_change='append_new_columns'
    )
}}

with

renamed as (

    select
        -- ids
        transaction_id,
        card_id,

        -- strings
        currency as currency_code,
        merchant_category,

        -- numerics
        amount,

        -- booleans
        amount < 0 as is_refund,

        -- dates
        cast(transaction_date as date) as transaction_date,

        -- timestamps
        transaction_date as transaction_at,

        -- metadata
        _loaded_at,
        current_timestamp as _dbt_loaded_at

    from {{ source('core_banking', 'transactions') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) - interval 3 hour from {{ this }})
    {% endif %}

)

select * from renamed
