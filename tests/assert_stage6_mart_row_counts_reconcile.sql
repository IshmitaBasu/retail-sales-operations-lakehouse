with comparisons as (
    select
        'dim_customer' as model_name,
        (select count(*) from {{ ref('dim_customer') }}) as model_rows,
        (select count(*) from {{ ref('view_customers') }}) as expected_rows

    union all

    select
        'dim_product',
        (select count(*) from {{ ref('dim_product') }}),
        (select count(*) from {{ ref('view_products') }})

    union all

    select
        'dim_fulfilment_centre',
        (select count(*) from {{ ref('dim_fulfilment_centre') }}),
        (select count(distinct fulfilment_centre_id) from {{ ref('view_fulfilments') }})

    union all

    select
        'fact_order_line',
        (select count(*) from {{ ref('fact_order_line') }}),
        (select count(*) from {{ ref('view_order_line_enriched') }})

    union all

    select
        'fact_order_fulfilment',
        (select count(*) from {{ ref('fact_order_fulfilment') }}),
        (select count(*) from {{ ref('view_fulfilment_enriched') }})
)

select *
from comparisons
where model_rows != expected_rows
