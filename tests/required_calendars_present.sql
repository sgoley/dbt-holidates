with required_calendars as (
    select 'us_government' as calendar_name
    union all select 'us_bank'
    union all select 'us_market'
    union all select 'canada'
    union all select 'china'
),

actual_calendars as (
    select distinct calendar_name
    from {{ ref('holidays') }}
)

select required_calendars.calendar_name
from required_calendars
left join actual_calendars
    on required_calendars.calendar_name = actual_calendars.calendar_name
where actual_calendars.calendar_name is null
