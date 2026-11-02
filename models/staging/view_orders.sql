select
    cast(order_id as string) as order_id,
    cast(customer_id as string) as customer_id,
    cast(order_created_at as timestamp) as order_created_at,
    lower(trim(cast(order_type as string))) as order_type,
    lower(trim(cast(sales_channel as string))) as sales_channel,
    lower(trim(cast(payment_status as string))) as payment_status,
    lower(trim(cast(order_status as string))) as order_status,
    upper(trim(cast(currency_code as string))) as currency_code,
    cast(updated_at as timestamp) as updated_at
from {{ source('retail_raw', 'orders') }}
