{{
    config(
        group='core',
        tags=['core'],
        meta={'owner': 'analytics-engineering'}
    )
}}

-- Every transaction must have an FX rate for its day and currency.
-- Without one, the transaction cannot be converted to EUR and would be lost
-- (inner join) or get a null EUR amount (left join) in later models.
-- With real ECB data this fails on weekends and holidays, until missing days
-- are filled with the last known rate.
select
    t.transaction_id,
    t.transaction_date,
    t.currency_code
from {{ ref('stg_core_banking__transactions') }} as t
left join {{ ref('stg_ecb__fx_rate') }} as f
    on  f.currency_code = t.currency_code
    and f.rate_date = t.transaction_date
where f.fx_rate_id is null
