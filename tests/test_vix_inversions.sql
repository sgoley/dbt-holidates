with expected_inversions as (
    select '2016-10' as contract_month, cast('2016-10-19' as date) as expected_vix_date, cast('2016-10-21' as date) as expected_spx_date
    union all select '2022-10', cast('2022-10-19' as date), cast('2022-10-21' as date)
    union all select '2023-07', cast('2023-07-19' as date), cast('2023-07-21' as date)
    union all select '2024-10', cast('2024-10-16' as date), cast('2024-10-18' as date)
),

vix_actual as (
    select
        contract_month,
        expiration_date,
        is_vix_inversion,
        days_to_equity_monthly_opex
    from {{ ref('us_options_expirations') }}
    where product_type = 'vix_monthly'
)

select
    e.contract_month,
    e.expected_vix_date,
    a.expiration_date,
    a.is_vix_inversion,
    a.days_to_equity_monthly_opex
from expected_inversions e
left join vix_actual a
    on e.contract_month = a.contract_month
where
    a.expiration_date != e.expected_vix_date
    or a.is_vix_inversion is not true
    or a.days_to_equity_monthly_opex >= 0
