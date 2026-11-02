with source_rows as (
    select
        order_line_id,
        order_id,
        customer_id,
        product_id,
        order_created_at,
        order_date,
        order_type,
        sales_channel,
        payment_status,
        order_status,
        currency_code,
        quantity,
        unit_price_eur,
        discount_amount_eur,
        unit_cost_eur,
        gross_sales_amount_eur,
        net_sales_amount_eur,
        cost_amount_eur,
        gross_margin_amount_eur,
        recognized_net_sales_amount_eur,
        order_updated_at,
        order_line_updated_at,
        incremental_watermark
    from {{ ref('view_order_line_enriched') }}
),

fact_rows as (
    select * from {{ ref('fact_order_line') }}
)

select coalesce(source_rows.order_line_id, fact_rows.order_line_id) as order_line_id
from source_rows
full outer join fact_rows
    on source_rows.order_line_id = fact_rows.order_line_id
where source_rows.order_line_id is null
    or fact_rows.order_line_id is null
    or not (source_rows.order_id <=> fact_rows.order_id)
    or not (source_rows.customer_id <=> fact_rows.customer_id)
    or not (source_rows.product_id <=> fact_rows.product_id)
    or not (source_rows.order_created_at <=> fact_rows.order_created_at)
    or not (source_rows.order_date <=> fact_rows.order_date)
    or not (source_rows.order_type <=> fact_rows.order_type)
    or not (source_rows.sales_channel <=> fact_rows.sales_channel)
    or not (source_rows.payment_status <=> fact_rows.payment_status)
    or not (source_rows.order_status <=> fact_rows.order_status)
    or not (source_rows.currency_code <=> fact_rows.currency_code)
    or not (source_rows.quantity <=> fact_rows.quantity)
    or not (source_rows.unit_price_eur <=> fact_rows.unit_price_eur)
    or not (source_rows.discount_amount_eur <=> fact_rows.discount_amount_eur)
    or not (source_rows.unit_cost_eur <=> fact_rows.unit_cost_eur)
    or not (source_rows.gross_sales_amount_eur <=> fact_rows.gross_sales_amount_eur)
    or not (source_rows.net_sales_amount_eur <=> fact_rows.net_sales_amount_eur)
    or not (source_rows.cost_amount_eur <=> fact_rows.cost_amount_eur)
    or not (source_rows.gross_margin_amount_eur <=> fact_rows.gross_margin_amount_eur)
    or not (
        source_rows.recognized_net_sales_amount_eur
        <=> fact_rows.recognized_net_sales_amount_eur
    )
    or not (source_rows.order_updated_at <=> fact_rows.order_updated_at)
    or not (source_rows.order_line_updated_at <=> fact_rows.order_line_updated_at)
    or not (source_rows.incremental_watermark <=> fact_rows.incremental_watermark)
