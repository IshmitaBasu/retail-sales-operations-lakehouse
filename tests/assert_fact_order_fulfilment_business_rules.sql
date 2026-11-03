select fulfilment_id
from {{ ref('fact_order_fulfilment') }}
where order_type != 'physical'
    or (picked_at is not null and picked_at < order_created_at)
    or (packed_at is not null and picked_at is not null and packed_at < picked_at)
    or (shipped_at is not null and packed_at is not null and shipped_at < packed_at)
    or (delivered_at is not null and shipped_at is not null and delivered_at < shipped_at)
    or (fulfilment_status = 'delivered' and delivered_at is null)
    or (fulfilment_status = 'delivered' and is_on_time_delivery is null)
    or (fulfilment_status != 'delivered' and is_on_time_delivery is not null)
    or (shipped_at is null and fulfilment_hours is not null)
    or (delivered_at is null and delivery_hours is not null)
    or fulfilment_hours < 0
    or delivery_hours < 0
    or is_delivered != (fulfilment_status = 'delivered')
    or is_cancelled != (fulfilment_status = 'cancelled')
