with comparisons as (
    select
        'view_customers' as model_name,
        (select count(*) from {{ ref('view_customers') }}) as model_rows,
        (select count(*) from {{ source('retail_raw', 'customers') }}) as expected_rows
    union all
    select
        'view_products',
        (select count(*) from {{ ref('view_products') }}),
        (select count(*) from {{ source('retail_raw', 'products') }})
    union all
    select
        'view_orders',
        (select count(*) from {{ ref('view_orders') }}),
        (select count(*) from {{ source('retail_raw', 'orders') }})
    union all
    select
        'view_order_lines',
        (select count(*) from {{ ref('view_order_lines') }}),
        (select count(*) from {{ source('retail_raw', 'order_lines') }})
    union all
    select
        'view_fulfilments',
        (select count(*) from {{ ref('view_fulfilments') }}),
        (select count(*) from {{ source('retail_raw', 'fulfilments') }})
    union all
    select
        'view_order_line_enriched',
        (select count(*) from {{ ref('view_order_line_enriched') }}),
        (select count(*) from {{ ref('view_order_lines') }})
    union all
    select
        'view_fulfilment_enriched',
        (select count(*) from {{ ref('view_fulfilment_enriched') }}),
        (select count(*) from {{ ref('view_fulfilments') }})
)

select *
from comparisons
where model_rows != expected_rows
