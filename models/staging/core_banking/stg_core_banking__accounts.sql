with

renamed as (

    select
        -- ids
        account_id,

        -- strings
        company_name,
        industry,
        country as country_code,
        plan_type,

        -- timestamps
        created_at

    from {{ source('core_banking', 'accounts') }}

)

select * from renamed
