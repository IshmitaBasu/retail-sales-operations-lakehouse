with fulfilments as (
    select * from {{ ref('view_fulfilments') }}
),

orders as (
    select * from {{ ref('view_orders') }}
),

enriched as (
    select
        fulfilments.fulfilment_id,
        fulfilments.order_id,
        orders.customer_id,
        orders.order_created_at,
        orders.order_status,
        orders.order_type,
        fulfilments.fulfilment_centre_id,
        fulfilments.fulfilment_centre_name,
        fulfilments.fulfilment_centre_region,
        fulfilments.carrier_name,
        fulfilments.fulfilment_status,
        fulfilments.picked_at,
        fulfilments.packed_at,
        fulfilments.shipped_at,
        fulfilments.promised_delivery_date,
        fulfilments.delivered_at,
        cast(
            case
                when fulfilments.shipped_at is not null
                    then round(
                        (unix_timestamp(fulfilments.shipped_at) - unix_timestamp(orders.order_created_at))
                        / 3600.0,
                        2
                    )
            end as decimal(18, 2)
        ) as fulfilment_hours,
        cast(
            case
                when fulfilments.shipped_at is not null
                    and fulfilments.delivered_at is not null
                    then round(
                        (unix_timestamp(fulfilments.delivered_at) - unix_timestamp(fulfilments.shipped_at))
                        / 3600.0,
                        2
                    )
            end as decimal(18, 2)
        ) as delivery_hours,
        case
            when fulfilments.fulfilment_status = 'delivered'
                then cast(to_date(fulfilments.delivered_at) <= fulfilments.promised_delivery_date as boolean)
        end as is_on_time_delivery,
        case
            when fulfilments.fulfilment_status = 'delivered' then true
            else false
        end as is_delivered,
        case
            when fulfilments.fulfilment_status = 'cancelled' then true
            else false
        end as is_cancelled,
        fulfilments.updated_at as fulfilment_updated_at,
        orders.updated_at as order_updated_at,
        greatest(fulfilments.updated_at, orders.updated_at) as record_updated_at
    from fulfilments
    inner join orders
        on fulfilments.order_id = orders.order_id
)

select * from enriched
