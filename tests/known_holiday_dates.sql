with expected as (
    select 'us_government' as calendar_name, 'Juneteenth National Independence Day' as holiday_name, cast('2021-06-19' as date) as holiday_date, cast('2021-06-18' as date) as observed_date
    union all select 'us_market', 'Good Friday', cast('2024-03-29' as date), cast('2024-03-29' as date)
    union all select 'canada', 'Christmas Day', cast('2021-12-25' as date), cast('2021-12-27' as date)
    union all select 'canada', 'Boxing Day', cast('2021-12-26' as date), cast('2021-12-28' as date)
    union all select 'china', 'Spring Festival', cast('2024-02-10' as date), cast('2024-02-10' as date)
),

actual as (
    select
        calendar_name,
        holiday_name,
        holiday_date,
        observed_date
    from {{ ref('holidays') }}
)

select expected.*
from expected
left join actual
    on expected.calendar_name = actual.calendar_name
    and expected.holiday_name = actual.holiday_name
    and expected.holiday_date = actual.holiday_date
    and expected.observed_date = actual.observed_date
where actual.calendar_name is null
