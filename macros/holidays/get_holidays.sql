{% macro get_holidays(calendar_name='all', start_year=none, end_year=none) %}
    {{ adapter.dispatch("get_holidays", "dbt_holidates")(calendar_name, start_year, end_year) }}
{% endmacro %}

{% macro default__get_holidays(calendar_name='all', start_year=none, end_year=none) %}
    {% set start_year = (start_year if start_year is not none else var("dbt_holidates_start_year", 2000)) | int %}
    {% set end_year = (end_year if end_year is not none else var("dbt_holidates_end_year", 2035)) | int %}

    {% if end_year < start_year %}
        {{ exceptions.raise_compiler_error("dbt_holidates.get_holidays end_year must be greater than or equal to start_year") }}
    {% endif %}

    {% set calendar_key = calendar_name | lower | replace("-", "_") | replace(" ", "_") %}

    {% if calendar_key == "all" %}
        select * from (
            {{ dbt_holidates._render_holiday_rows(dbt_holidates._us_government_holiday_rows(start_year, end_year)) }}
        ) as us_government_holidays
        union all
        select * from (
            {{ dbt_holidates._render_holiday_rows(dbt_holidates._us_bank_holiday_rows(start_year, end_year)) }}
        ) as us_bank_holidays
        union all
        select * from (
            {{ dbt_holidates._render_holiday_rows(dbt_holidates._us_market_holiday_rows(start_year, end_year)) }}
        ) as us_market_holidays
        union all
        select * from (
            {{ dbt_holidates._render_holiday_rows(dbt_holidates._canada_holiday_rows(start_year, end_year)) }}
        ) as canada_holidays
        union all
        select * from (
            {{ dbt_holidates._render_holiday_rows(dbt_holidates._china_holiday_rows(start_year, end_year)) }}
        ) as china_holidays
    {% else %}
        {% set rows = [] %}

        {% if calendar_key in ["us_government", "us_gov", "us_federal", "united_states_government"] %}
            {% do rows.extend(dbt_holidates._us_government_holiday_rows(start_year, end_year)) %}
        {% endif %}

        {% if calendar_key in ["us_bank", "united_states_bank", "federal_reserve"] %}
            {% do rows.extend(dbt_holidates._us_bank_holiday_rows(start_year, end_year)) %}
        {% endif %}

        {% if calendar_key in ["us_market", "united_states_market", "nyse"] %}
            {% do rows.extend(dbt_holidates._us_market_holiday_rows(start_year, end_year)) %}
        {% endif %}

        {% if calendar_key in ["canada", "canadian", "ca"] %}
            {% do rows.extend(dbt_holidates._canada_holiday_rows(start_year, end_year)) %}
        {% endif %}

        {% if calendar_key in ["china", "cn", "prc"] %}
            {% do rows.extend(dbt_holidates._china_holiday_rows(start_year, end_year)) %}
        {% endif %}

        {% if rows | length == 0 %}
            {{ exceptions.raise_compiler_error("Unknown dbt_holidates calendar_name: " ~ calendar_name) }}
        {% endif %}

        {{ dbt_holidates._render_holiday_rows(rows) }}
    {% endif %}
{% endmacro %}
