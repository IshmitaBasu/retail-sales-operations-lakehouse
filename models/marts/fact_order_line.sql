{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_line_id',
        file_format='delta',
        on_schema_change='fail'
    )
}}

with enriched_order_lines as (
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
    from {{ ref('view_order_line_enriched') }} as source_rows

    {% if is_incremental() %}
        where
            source_rows.incremental_watermark > (
                select coalesce(max(incremental_watermark), cast('1900-01-01' as timestamp))
                from {{ this }}
            )
            or not exists (
                select 1
                from {{ this }} as existing_rows
                where existing_rows.order_line_id = source_rows.order_line_id
            )
    {% endif %}
)

select * from enriched_order_lines
