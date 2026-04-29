# dbt_holidates

`dbt_holidates` is a dbt package that provides ready-to-use holiday calendar models and a compile-time macro for generating holiday rows across a configurable year range.

## Included calendars

| Calendar | Model | Macro key | Notes |
| --- | --- | --- | --- |
| US Government Holidays | `us_government_holidays` | `us_government` | US federal holidays, including Juneteenth from 2021. |
| US Bank Holidays | `us_bank_holidays` | `us_bank` | Federal Reserve-style bank holidays. |
| US Market Holidays | `us_market_holidays` | `us_market` | NYSE regular holidays plus major historical full-day closures. |
| Canadian Holidays | `canada_holidays` | `canada` | Canadian federal holidays. |
| China Holidays | `china_holidays` | `china` | China public holiday festival dates, with curated lunar dates through 2050. |
| All calendars | `holidays` | `all` | Canonical union of every calendar above. |

## Installation

### Add the package

Include `dbt_holidates` in your dbt project's `packages.yml` file:

```yaml
packages:
  - git: "https://github.com/sgoley/dbt-holidates.git"
        revision: v1.0.0
```

Then install the package:

```bash
dbt deps
```

### Load the models

Run the dbt_holidates models in your project:

```bash
dbt run --select dbt_holidates
dbt test --select dbt_holidates
```

The models will be created as views in your warehouse under the `dbt_holidates` schema. You can now reference them via `{{ ref() }}` in your own models.

## Configuration

The package defaults to generating holidays from 2000 through 2035. Override the range in your root project's `dbt_project.yml`:

```yaml
vars:
  dbt_holidates_start_year: 2000
  dbt_holidates_end_year: 2045
```

To direct package models to a custom destination database/schema, set:

```yaml
vars:
    dbt_holidates_destination_database: analytics
    dbt_holidates_destination_schema: reference
```

The same range can be controlled directly when calling the macro:

```sql
select *
from (
    {{ dbt_holidates.get_holidays("us_market", 2020, 2030) }}
) as holidays
```

Supported macro keys are `all`, `us_government`, `us_bank`, `us_market`, `canada`, and `china`. A few aliases are also accepted, such as `us_federal`, `nyse`, `ca`, and `cn`.

## Usage examples

### Join holidays with your date dimension

The most common use case is to flag holidays in your date dimension. Here's an example using a date spine:

```sql
with date_spine as (
    select date_day from {{ ref('your_date_dim') }}
),

holidays_flagged as (
    select
        d.date_day,
        coalesce(h.holiday_name, 'Regular Day') as holiday_name,
        h.calendar_name,
        case when h.holiday_date is not null then true else false end as is_holiday,
        case when h.observed_date = d.date_day then true else false end as is_observed,
        extract(dayofweek from d.date_day) as day_of_week
    from date_spine d
    left join {{ ref('holidays') }} h
        on d.date_day = h.observed_date
        and h.calendar_name = 'us_government'
)

select * from holidays_flagged
```

### Filter to specific holidays

You can filter for specific calendars or holiday types:

```sql
select
    observed_date,
    holiday_name,
    calendar_display_name
from {{ ref('us_market_holidays') }}
where holiday_type = 'market_closure'
  and observed_date >= current_date
  and observed_date < current_date + interval 30 day
order by observed_date
```

### Exclude holidays from business day calculations

Use holidays to calculate working days:

```sql
with date_range as (
    select date_day from {{ ref('your_date_dim') }}
    where date_day between '2024-01-01' and '2024-12-31'
),

working_days as (
    select
        d.date_day,
        extract(dayofweek from d.date_day) as day_of_week,
        case
            when extract(dayofweek from d.date_day) in (1, 7) then false
            when h.holiday_date is not null then false
            else true
        end as is_working_day
    from date_range d
    left join {{ ref('us_government_holidays') }} h
        on d.date_day = h.observed_date
)

select sum(is_working_day::int) as total_working_days from working_days
```

### Use the macro in your own models

Generate custom holiday calendars by calling the macro directly. For example, to combine US and Canadian holidays:

```sql
with us_holidays as (
    {{ dbt_holidates.get_holidays("us_government") }}
),

canada_holidays as (
    {{ dbt_holidates.get_holidays("canada") }}
)

select * from us_holidays
union all
select * from canada_holidays
```

Or generate holidays for a specific year range:

```sql
{{ dbt_holidates.get_holidays("us_market", 2024, 2026) }}
```

### Multi-calendar lookups

Check if a date is a holiday across multiple calendars:

```sql
select
    d.date_day,
    count(distinct h.calendar_name) as num_holidays,
    array_agg(distinct h.holiday_name) as holidays
from {{ ref('your_date_dim') }} d
left join {{ ref('holidays') }} h
    on d.date_day = h.observed_date
where d.date_day >= current_date - interval 90 day
  and d.date_day <= current_date
group by d.date_day
having count(distinct h.calendar_name) > 0
order by d.date_day desc
```



## Output columns

Every model returns the same shape:

| Column | Description |
| --- | --- |
| `holiday_date` | Actual date of the holiday. |
| `observed_date` | Date on which the calendar observes the holiday. |
| `calendar_name` | Stable machine-readable calendar identifier. |
| `calendar_display_name` | Human-readable calendar label. |
| `country_code` | Country code for the calendar. |
| `subdivision` | Optional subdivision, exchange, or jurisdiction. |
| `holiday_name` | Human-readable holiday name. |
| `holiday_type` | Holiday category, such as `federal_holiday`, `bank_holiday`, `market_holiday`, `market_closure`, or `public_holiday`. |
| `is_observed` | Boolean flag indicating the row is observed by the calendar. |
| `rule_description` | Rule or historical note used to generate the holiday row. |

## Important calendar notes

Holiday calendars are legal and operational calendars that can change. This package is designed to be a useful dbt-native starting point:

- US Government and US Bank holidays are rule generated from 2000 forward.
- US Market holidays are rule generated from 2000 forward and include selected full-day NYSE historical closures.
- Canadian holidays are federal holidays and do not include every province-specific statutory holiday.
- China includes fixed public holiday festival dates plus curated lunar festival dates for Spring Festival, Dragon Boat Festival, and Mid-Autumn Festival from 2000 through 2050. It does not model official State Council working-weekend swaps or multi-day Golden Week bridge schedules.

For calendars that require organization-specific closure rules, call `dbt_holidates.get_holidays()` in your own model and union additional rows there.

## Quick reference

### Macro signature

```sql
{{ dbt_holidates.get_holidays(calendar_name, start_year, end_year) }}
```

| Parameter | Required | Default | Description |
| --- | --- | --- | --- |
| `calendar_name` | Yes | - | One of: `all`, `us_government`, `us_bank`, `us_market`, `canada`, `china` |
| `start_year` | No | `var('dbt_holidates_start_year', 2000)` | First year to generate holidays for |
| `end_year` | No | `var('dbt_holidates_end_year', 2035)` | Last year to generate holidays for |

### Available models

All models are views in the `dbt_holidates` schema:

- `dbt_holidates.holidays` — Union of all calendars
- `dbt_holidates.us_government_holidays` — US federal holidays
- `dbt_holidates.us_bank_holidays` — Federal Reserve bank holidays
- `dbt_holidates.us_market_holidays` — NYSE market holidays
- `dbt_holidates.canada_holidays` — Canadian federal holidays
- `dbt_holidates.china_holidays` — China public holidays

All models produce the same column schema, making them safe to union together.

## Integration tips

### Working with your data warehouse

Most SQL dialects support the patterns shown. For dialect-specific date functions:

- **Postgres/Redshift**: Use `extract(dow from date_col)` for day of week
- **BigQuery**: Use `extract(dayofweek from date_col)` or `format_date('%w', date_col)`
- **Snowflake**: Use `dayofweek(date_col)` or `to_number(to_char(date_col, 'D'))`
- **DuckDB**: Use `extract(dayofweek from date_col)` or `dayofweek(date_col)`

### Best practices

1. **Always join on `observed_date`**, not `holiday_date`. The `observed_date` is the actual day the calendar observes the holiday (e.g., Monday if the holiday falls on a weekend).

2. **Filter by `calendar_name`** when you only need one calendar to avoid duplicate rows:
   ```sql
   left join {{ ref('holidays') }} h
       on d.date_day = h.observed_date
       and h.calendar_name = 'us_government'
   ```

3. **Materialize locally** if you reference the holidays frequently. Consider changing the materialization in your `dbt_project.yml`:
   ```yaml
   models:
       dbt_holidates:
           holidays:
               +materialized: table  # Instead of view
   ```

4. **Extend with custom holidays** by wrapping the macro and adding your organization's closure dates:
   ```sql
   with dbt_holidates_gen as (
       {{ dbt_holidates.get_holidays("us_government") }}
   ),
   
   custom_closures as (
       select
           cast('2024-11-29' as date) as holiday_date,
           cast('2024-11-29' as date) as observed_date,
           'custom' as calendar_name,
           'Custom Closures' as calendar_display_name,
           'US' as country_code,
           null as subdivision,
           'Company Summer Recess' as holiday_name,
           'company_closure' as holiday_type,
           true as is_observed,
           'Organization-specific closure' as rule_description
   )
   
   select * from dbt_holidates_gen
   union all
   select * from custom_closures
   ```
