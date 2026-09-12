with expected_rolls as (
    -- Good Friday rolls 3rd Friday to Thursday
    select 'equity_monthly' as product_type, '2022-04' as contract_month, cast('2022-04-14' as date) as expected_date, true as expected_rolled
    union all select 'equity_monthly', '2025-04', cast('2025-04-17' as date), true
    -- Juneteenth rolls Wednesday VIX to Tuesday
    union all select 'vix_monthly', '2024-06', cast('2024-06-18' as date), true
    -- Month-end on weekend rolls to Friday
    union all select 'index_eom', '2022-07', cast('2022-07-29' as date), true
    -- Quarter-end on weekend rolls to Friday
    union all select 'index_eoq', '2024-03', cast('2024-03-28' as date), true
),

actual as (
    select
        product_type,
        contract_month,
        expiration_date,
        is_holiday_rolled
    from {{ ref('us_options_expirations') }}
)

select
    e.product_type,
    e.contract_month,
    e.expected_date,
    a.expiration_date,
    e.expected_rolled,
    a.is_holiday_rolled
from expected_rolls e
left join actual a
    on e.product_type = a.product_type
    and e.contract_month = a.contract_month
where
    a.expiration_date != e.expected_date
    or a.is_holiday_rolled != e.expected_rolled
