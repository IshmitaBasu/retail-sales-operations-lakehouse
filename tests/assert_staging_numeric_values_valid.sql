select
    'order_line' as record_type,
    order_line_id as record_id
from {{ ref('view_order_lines') }}
where quantity <= 0
    or unit_price_eur < 0
    or discount_amount_eur < 0
    or discount_amount_eur > quantity * unit_price_eur

union all

select
    'product' as record_type,
    product_id as record_id
from {{ ref('view_products') }}
where unit_cost_eur < 0
    or list_price_eur < 0
