select
    calendar_name,
    observed_date,
    holiday_name,
    count(*) as row_count
from {{ ref('holidays') }}
group by 1, 2, 3
having count(*) > 1
