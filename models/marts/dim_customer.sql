select
    customer_id,
    signup_date,
    customer_segment,
    region,
    country_code,
    updated_at as customer_updated_at
from {{ ref('view_customers') }}
