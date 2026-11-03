select
    product_id,
    product_name,
    category,
    product_type,
    unit_cost_eur,
    list_price_eur,
    is_active,
    updated_at as product_updated_at
from {{ ref('view_products') }}
