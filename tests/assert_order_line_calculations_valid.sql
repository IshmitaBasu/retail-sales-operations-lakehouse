select order_line_id
from {{ ref('view_order_line_enriched') }}
where abs(gross_sales_amount_eur - round(quantity * unit_price_eur, 2)) > 0.01
    or abs(
        net_sales_amount_eur
        - round((quantity * unit_price_eur) - discount_amount_eur, 2)
    ) > 0.01
    or abs(cost_amount_eur - round(quantity * unit_cost_eur, 2)) > 0.01
    or abs(gross_margin_amount_eur - round(net_sales_amount_eur - cost_amount_eur, 2)) > 0.01
    or abs(
        recognized_net_sales_amount_eur
        - case when order_status = 'cancelled' then 0 else net_sales_amount_eur end
    ) > 0.01
    or incremental_watermark != greatest(order_updated_at, order_line_updated_at)
