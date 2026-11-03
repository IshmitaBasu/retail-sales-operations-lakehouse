with event_dates as (
    select order_date as event_date
    from {{ ref('view_order_line_enriched') }}

    union all

    select promised_delivery_date as event_date
    from {{ ref('view_fulfilment_enriched') }}

    union all

    select to_date(delivered_at) as event_date
    from {{ ref('view_fulfilment_enriched') }}
    where delivered_at is not null
),

date_bounds as (
    select
        make_date(year(min(event_date)), 1, 1) as start_date,
        make_date(year(max(event_date)), 12, 31) as end_date
    from event_dates
),

date_spine as (
    select explode(sequence(start_date, end_date, interval 1 day)) as date_day
    from date_bounds
)

select
    date_day,
    cast(date_format(date_day, 'yyyyMMdd') as integer) as date_key,
    year(date_day) as calendar_year,
    quarter(date_day) as calendar_quarter,
    month(date_day) as month_number,
    date_format(date_day, 'MMMM') as month_name,
    date_format(date_day, 'yyyy-MM') as year_month,
    weekofyear(date_day) as week_of_year,
    dayofmonth(date_day) as day_of_month,
    weekday(date_day) + 1 as iso_day_of_week,
    date_format(date_day, 'EEEE') as day_name,
    cast(date_trunc('MONTH', date_day) as date) as month_start_date,
    cast(date_trunc('QUARTER', date_day) as date) as quarter_start_date,
    make_date(year(date_day), 1, 1) as year_start_date,
    cast(weekday(date_day) >= 5 as boolean) as is_weekend
from date_spine
