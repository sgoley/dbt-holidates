{% macro _early_closure_row(calendar_name, country_code, subdivision, closure_date, close_time, event_name, closure_type, description) %}
    {{ return({
        "calendar_name": calendar_name,
        "country_code": country_code,
        "subdivision": subdivision,
        "closure_date": closure_date,
        "close_time": close_time,
        "event_name": event_name,
        "closure_type": closure_type,
        "description": description
    }) }}
{% endmacro %}

{% macro _us_early_market_closure_rows(start_year, end_year) %}
    {% set rows = [] %}
    {% for year in range(start_year, end_year + 1) %}
        {% set calendar = "us_market" %}
        {% set country = "US" %}
        {% set subdivision = "NYSE" %}
        {% set close_time = "13:00 EST" %}
        {% set closure_type = "early_close" %}

        {# 1. Day after Thanksgiving (Black Friday) #}
        {% set thanksgiving = dbt_holidates._nth_weekday(year, 11, 3, 4) %}
        {% set black_friday = thanksgiving + modules.datetime.timedelta(days=1) %}
        {% do rows.append(dbt_holidates._early_closure_row(calendar, country, subdivision, black_friday, close_time, "Day after Thanksgiving (Black Friday)", closure_type, "Day after Thanksgiving, regular early market close at 1:00 PM EST")) %}

        {# 2. Day before Independence Day (July 3) when July 4 falls on Tuesday, Wednesday, Thursday, or Friday #}
        {% set july4 = dbt_holidates._date(year, 7, 4) %}
        {% if july4.weekday() in [1, 2, 3, 4] %}
            {% set july3 = dbt_holidates._date(year, 7, 3) %}
            {% do rows.append(dbt_holidates._early_closure_row(calendar, country, subdivision, july3, close_time, "Day before Independence Day", closure_type, "Trading day prior to Independence Day, early market close at 1:00 PM EST")) %}
        {% endif %}

        {# 3. Christmas Eve (December 24) when falling on Monday, Tuesday, Wednesday, or Thursday #}
        {% set xmas_eve = dbt_holidates._date(year, 12, 24) %}
        {% if xmas_eve.weekday() in [0, 1, 2, 3] %}
            {% do rows.append(dbt_holidates._early_closure_row(calendar, country, subdivision, xmas_eve, close_time, "Christmas Eve", closure_type, "Christmas Eve, early market close at 1:00 PM EST")) %}
        {% endif %}
    {% endfor %}
    {{ return(rows) }}
{% endmacro %}

{% macro _render_early_closure_rows(rows) %}
    {% if rows | length == 0 %}
        select
            cast(null as date) as closure_date,
            cast(null as {{ dbt.type_string() }}) as calendar_name,
            cast(null as {{ dbt.type_string() }}) as country_code,
            cast(null as {{ dbt.type_string() }}) as subdivision,
            cast(null as {{ dbt.type_string() }}) as close_time,
            cast(null as {{ dbt.type_string() }}) as event_name,
            cast(null as {{ dbt.type_string() }}) as closure_type,
            cast(null as {{ dbt.type_string() }}) as description
        where 1 = 0
    {% else %}
        {% for row in rows | sort(attribute="closure_date,event_name") %}
            {% if not loop.first %}union all{% endif %}
            select
                cast('{{ row["closure_date"].isoformat() }}' as date) as closure_date,
                '{{ row["calendar_name"] | replace("'", "''") }}' as calendar_name,
                '{{ row["country_code"] | replace("'", "''") }}' as country_code,
                '{{ row["subdivision"] | replace("'", "''") }}' as subdivision,
                '{{ row["close_time"] | replace("'", "''") }}' as close_time,
                '{{ row["event_name"] | replace("'", "''") }}' as event_name,
                '{{ row["closure_type"] | replace("'", "''") }}' as closure_type,
                '{{ row["description"] | replace("'", "''") }}' as description
        {% endfor %}
    {% endif %}
{% endmacro %}

{% macro get_early_closures(calendar_name='us_market', start_year=none, end_year=none) %}
    {% set start_year = (start_year if start_year is not none else var("dbt_holidates_start_year", 2000)) | int %}
    {% set end_year = (end_year if end_year is not none else var("dbt_holidates_end_year", 2035)) | int %}

    {% if end_year < start_year %}
        {{ exceptions.raise_compiler_error("dbt_holidates.get_early_closures end_year must be greater than or equal to start_year") }}
    {% endif %}

    {{ dbt_holidates._render_early_closure_rows(dbt_holidates._us_early_market_closure_rows(start_year, end_year)) }}
{% endmacro %}
