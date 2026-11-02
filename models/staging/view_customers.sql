select
    cast(customer_id as string) as customer_id,
    cast(signup_date as date) as signup_date,
    lower(trim(cast(customer_segment as string))) as customer_segment,
    initcap(trim(cast(region as string))) as region,
    upper(trim(cast(country_code as string))) as country_code,
    cast(updated_at as timestamp) as updated_at
from {{ source('retail_raw', 'customers') }}
