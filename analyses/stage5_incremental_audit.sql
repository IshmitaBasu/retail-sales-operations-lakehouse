with source_rows as (
    select * from {{ ref('view_order_line_enriched') }}
),

fact_rows as (
    select * from {{ ref('fact_order_line') }}
),

comparison as (
    select
        source_rows.order_line_id as source_key,
        fact_rows.order_line_id as fact_key,
        case
            when source_rows.order_line_id is not null
                and fact_rows.order_line_id is not null
                and (
                    not (source_rows.order_status <=> fact_rows.order_status)
                    or not (source_rows.payment_status <=> fact_rows.payment_status)
                    or not (source_rows.discount_amount_eur <=> fact_rows.discount_amount_eur)
                    or not (
                        source_rows.recognized_net_sales_amount_eur
                        <=> fact_rows.recognized_net_sales_amount_eur
                    )
                    or not (source_rows.order_updated_at <=> fact_rows.order_updated_at)
                    or not (source_rows.order_line_updated_at <=> fact_rows.order_line_updated_at)
                    or not (source_rows.incremental_watermark <=> fact_rows.incremental_watermark)
                )
                then 1
            else 0
        end as is_changed_existing
    from source_rows
    full outer join fact_rows
        on source_rows.order_line_id = fact_rows.order_line_id
),

fact_duplicates as (
    select count(*) as duplicate_key_groups
    from (
        select order_line_id
        from fact_rows
        group by order_line_id
        having count(*) > 1
    )
)

select
    (select count(*) from source_rows) as source_rows,
    (select count(*) from fact_rows) as fact_rows,
    sum(case when fact_key is null then 1 else 0 end) as missing_in_fact,
    sum(case when source_key is null then 1 else 0 end) as unexpected_in_fact,
    sum(is_changed_existing) as changed_existing_rows,
    (select duplicate_key_groups from fact_duplicates) as duplicate_key_groups
from comparison
