select
    cast(product_id as string) as product_id,
    trim(cast(product_name as string)) as product_name,
    trim(cast(category as string)) as category,
    lower(trim(cast(product_type as string))) as product_type,
    cast(unit_cost_eur as decimal(18, 2)) as unit_cost_eur,
    cast(list_price_eur as decimal(18, 2)) as list_price_eur,
    cast(is_active as boolean) as is_active,
    cast(updated_at as timestamp) as updated_at
from {{ source('retail_raw', 'products') }}
