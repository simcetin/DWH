with

renamed as (

    select
        -- ids
        {{ dbt.concat(["cast(date as varchar)", "'-'", "currency"]) }} as fx_rate_id,

        -- strings
        currency as currency_code,

        -- numerics
        eur_rate,

        -- dates
        date as rate_date

    from {{ source('ecb', 'fx_rate') }}

)

select * from renamed
