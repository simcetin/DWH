-- One row per customer with their order totals.
-- Customers without orders are kept (left join) with 0 orders.
with customers as (
    select * from {{ ref('example_customers') }}
),

orders as (
    select * from {{ ref('example_orders') }}
)

select
    c.customer_id,
    c.first_name,
    c.country,
    count(o.order_id)              as order_count,
    coalesce(sum(o.amount), 0)     as total_amount,
    min(o.order_date)              as first_order_date
from customers c
left join orders o
    on o.customer_id = c.customer_id
group by 1, 2, 3
order by c.customer_id
