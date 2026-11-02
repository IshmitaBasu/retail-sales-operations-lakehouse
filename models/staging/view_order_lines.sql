select
    cast(order_line_id as string) as order_line_id,
    cast(order_id as string) as order_id,
    cast(product_id as string) as product_id,
    cast(quantity as integer) as quantity,
    cast(unit_price_eur as decimal(18, 2)) as unit_price_eur,
    cast(discount_amount_eur as decimal(18, 2)) as discount_amount_eur,
    cast(updated_at as timestamp) as updated_at
from {{ source('retail_raw', 'order_lines') }}
