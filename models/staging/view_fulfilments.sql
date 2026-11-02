select
    cast(fulfilment_id as string) as fulfilment_id,
    cast(order_id as string) as order_id,
    cast(fulfilment_centre_id as string) as fulfilment_centre_id,
    trim(cast(fulfilment_centre_name as string)) as fulfilment_centre_name,
    initcap(trim(cast(fulfilment_centre_region as string))) as fulfilment_centre_region,
    trim(cast(carrier_name as string)) as carrier_name,
    lower(trim(cast(fulfilment_status as string))) as fulfilment_status,
    cast(picked_at as timestamp) as picked_at,
    cast(packed_at as timestamp) as packed_at,
    cast(shipped_at as timestamp) as shipped_at,
    cast(promised_delivery_date as date) as promised_delivery_date,
    cast(delivered_at as timestamp) as delivered_at,
    cast(updated_at as timestamp) as updated_at
from {{ source('retail_raw', 'fulfilments') }}
