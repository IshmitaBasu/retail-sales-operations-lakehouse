with source_rows as (
    select
        fulfilment_id,
        order_id,
        customer_id,
        fulfilment_centre_id,
        order_created_at,
        cast(order_created_at as date) as order_date,
        order_status,
        order_type,
        carrier_name,
        fulfilment_status,
        picked_at,
        cast(picked_at as date) as picked_date,
        packed_at,
        cast(packed_at as date) as packed_date,
        shipped_at,
        cast(shipped_at as date) as shipped_date,
        promised_delivery_date,
        delivered_at,
        cast(delivered_at as date) as delivered_date,
        fulfilment_hours,
        delivery_hours,
        is_on_time_delivery,
        is_delivered,
        is_cancelled,
        fulfilment_updated_at,
        order_updated_at,
        record_updated_at
    from {{ ref('view_fulfilment_enriched') }}
),

fact_rows as (
    select * from {{ ref('fact_order_fulfilment') }}
)

select coalesce(source_rows.fulfilment_id, fact_rows.fulfilment_id) as fulfilment_id
from source_rows
full outer join fact_rows
    on source_rows.fulfilment_id = fact_rows.fulfilment_id
where source_rows.fulfilment_id is null
    or fact_rows.fulfilment_id is null
    or not (source_rows.order_id <=> fact_rows.order_id)
    or not (source_rows.customer_id <=> fact_rows.customer_id)
    or not (source_rows.fulfilment_centre_id <=> fact_rows.fulfilment_centre_id)
    or not (source_rows.order_created_at <=> fact_rows.order_created_at)
    or not (source_rows.order_date <=> fact_rows.order_date)
    or not (source_rows.order_status <=> fact_rows.order_status)
    or not (source_rows.order_type <=> fact_rows.order_type)
    or not (source_rows.carrier_name <=> fact_rows.carrier_name)
    or not (source_rows.fulfilment_status <=> fact_rows.fulfilment_status)
    or not (source_rows.picked_at <=> fact_rows.picked_at)
    or not (source_rows.picked_date <=> fact_rows.picked_date)
    or not (source_rows.packed_at <=> fact_rows.packed_at)
    or not (source_rows.packed_date <=> fact_rows.packed_date)
    or not (source_rows.shipped_at <=> fact_rows.shipped_at)
    or not (source_rows.shipped_date <=> fact_rows.shipped_date)
    or not (source_rows.promised_delivery_date <=> fact_rows.promised_delivery_date)
    or not (source_rows.delivered_at <=> fact_rows.delivered_at)
    or not (source_rows.delivered_date <=> fact_rows.delivered_date)
    or not (source_rows.fulfilment_hours <=> fact_rows.fulfilment_hours)
    or not (source_rows.delivery_hours <=> fact_rows.delivery_hours)
    or not (source_rows.is_on_time_delivery <=> fact_rows.is_on_time_delivery)
    or not (source_rows.is_delivered <=> fact_rows.is_delivered)
    or not (source_rows.is_cancelled <=> fact_rows.is_cancelled)
    or not (source_rows.fulfilment_updated_at <=> fact_rows.fulfilment_updated_at)
    or not (source_rows.order_updated_at <=> fact_rows.order_updated_at)
    or not (source_rows.record_updated_at <=> fact_rows.record_updated_at)
