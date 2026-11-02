with order_lines as (
    select * from {{ ref('view_order_lines') }}
),

orders as (
    select * from {{ ref('view_orders') }}
),

products as (
    select * from {{ ref('view_products') }}
),

enriched as (
    select
        order_lines.order_line_id,
        order_lines.order_id,
        orders.customer_id,
        order_lines.product_id,
        orders.order_created_at,
        cast(orders.order_created_at as date) as order_date,
        orders.order_type,
        orders.sales_channel,
        orders.payment_status,
        orders.order_status,
        orders.currency_code,
        products.product_name,
        products.category,
        products.product_type,
        order_lines.quantity,
        order_lines.unit_price_eur,
        order_lines.discount_amount_eur,
        products.unit_cost_eur,
        cast(round(order_lines.quantity * order_lines.unit_price_eur, 2) as decimal(18, 2))
            as gross_sales_amount_eur,
        cast(round(
            (order_lines.quantity * order_lines.unit_price_eur) - order_lines.discount_amount_eur,
            2
        ) as decimal(18, 2)) as net_sales_amount_eur,
        cast(round(order_lines.quantity * products.unit_cost_eur, 2) as decimal(18, 2))
            as cost_amount_eur,
        cast(round(
            (
                (order_lines.quantity * order_lines.unit_price_eur)
                - order_lines.discount_amount_eur
            ) - (order_lines.quantity * products.unit_cost_eur),
            2
        ) as decimal(18, 2)) as gross_margin_amount_eur,
        cast(
            case
                when orders.order_status = 'cancelled' then 0
                else round(
                    (order_lines.quantity * order_lines.unit_price_eur)
                    - order_lines.discount_amount_eur,
                    2
                )
            end as decimal(18, 2)
        ) as recognized_net_sales_amount_eur,
        orders.updated_at as order_updated_at,
        order_lines.updated_at as order_line_updated_at,
        greatest(orders.updated_at, order_lines.updated_at) as incremental_watermark
    from order_lines
    inner join orders
        on order_lines.order_id = orders.order_id
    inner join products
        on order_lines.product_id = products.product_id
)

select * from enriched
