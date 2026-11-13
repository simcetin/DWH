{{ config(tags=['core']) }}

with

renamed as (

    select
        -- ids
        card_id,
        account_id,

        -- strings
        card_name,
        status as card_status,
        card_type,

        -- timestamps
        created_at

    from {{ source('core_banking', 'virtual_cards') }}

)

select * from renamed
