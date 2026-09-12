select * from {{ ref('us_government_holidays') }}
union all
select * from {{ ref('us_bank_holidays') }}
union all
select * from {{ ref('us_market_holidays') }}
union all
select * from {{ ref('canada_holidays') }}
union all
select * from {{ ref('china_holidays') }}

