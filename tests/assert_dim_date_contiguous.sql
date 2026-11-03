with ordered_dates as (
    select
        date_day,
        lag(date_day) over (order by date_day) as previous_date
    from {{ ref('dim_date') }}
),

date_summary as (
    select
        min(date_day) as min_date,
        max(date_day) as max_date,
        count(*) as date_rows
    from {{ ref('dim_date') }}
)

select cast(date_day as string) as failure
from ordered_dates
where previous_date is not null
    and datediff(date_day, previous_date) != 1

union all

select 'date dimension does not begin on 1 January' as failure
from date_summary
where month(min_date) != 1 or day(min_date) != 1

union all

select 'date dimension does not end on 31 December' as failure
from date_summary
where month(max_date) != 12 or day(max_date) != 31

union all

select 'date dimension row count does not match its inclusive range' as failure
from date_summary
where date_rows != datediff(max_date, min_date) + 1
