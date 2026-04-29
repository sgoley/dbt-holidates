{% macro _date(year, month, day) %}
    {{ return(modules.datetime.date(year | int, month | int, day | int)) }}
{% endmacro %}

{% macro _nth_weekday(year, month, weekday, occurrence) %}
    {% set first_day = dbt_holidates._date(year, month, 1) %}
    {% set offset = (weekday - first_day.weekday() + 7) % 7 %}
    {{ return(first_day + modules.datetime.timedelta(days=offset + (7 * ((occurrence | int) - 1)))) }}
{% endmacro %}

{% macro _last_weekday(year, month, weekday) %}
    {% if (month | int) == 12 %}
        {% set next_month = dbt_holidates._date((year | int) + 1, 1, 1) %}
    {% else %}
        {% set next_month = dbt_holidates._date(year, (month | int) + 1, 1) %}
    {% endif %}
    {% set last_day = next_month - modules.datetime.timedelta(days=1) %}
    {% set offset = (last_day.weekday() - weekday + 7) % 7 %}
    {{ return(last_day - modules.datetime.timedelta(days=offset)) }}
{% endmacro %}

{% macro _observed_weekday(actual_date) %}
    {% if actual_date.weekday() == 5 %}
        {{ return(actual_date - modules.datetime.timedelta(days=1)) }}
    {% elif actual_date.weekday() == 6 %}
        {{ return(actual_date + modules.datetime.timedelta(days=1)) }}
    {% else %}
        {{ return(actual_date) }}
    {% endif %}
{% endmacro %}

{% macro _observed_next_weekday(actual_date) %}
    {% if actual_date.weekday() == 5 %}
        {{ return(actual_date + modules.datetime.timedelta(days=2)) }}
    {% elif actual_date.weekday() == 6 %}
        {{ return(actual_date + modules.datetime.timedelta(days=1)) }}
    {% else %}
        {{ return(actual_date) }}
    {% endif %}
{% endmacro %}

{% macro _easter_sunday(year) %}
    {% set a = (year | int) % 19 %}
    {% set b = ((year | int) // 100) %}
    {% set c = ((year | int) % 100) %}
    {% set d = (b // 4) %}
    {% set e = (b % 4) %}
    {% set f = ((b + 8) // 25) %}
    {% set g = ((b - f + 1) // 3) %}
    {% set h = ((19 * a + b - d - g + 15) % 30) %}
    {% set i = (c // 4) %}
    {% set k = (c % 4) %}
    {% set l = ((32 + 2 * e + 2 * i - h - k) % 7) %}
    {% set m = ((a + 11 * h + 22 * l) // 451) %}
    {% set month = ((h + l - 7 * m + 114) // 31) %}
    {% set day = (((h + l - 7 * m + 114) % 31) + 1) %}
    {{ return(dbt_holidates._date(year, month, day)) }}
{% endmacro %}

{% macro _good_friday(year) %}
    {{ return(dbt_holidates._easter_sunday(year) - modules.datetime.timedelta(days=2)) }}
{% endmacro %}

{% macro _canada_victoria_day(year) %}
    {% set may_25 = dbt_holidates._date(year, 5, 25) %}
    {% set offset = (may_25.weekday() + 7) % 7 %}
    {% if offset == 0 %}
        {% set offset = 7 %}
    {% endif %}
    {{ return(may_25 - modules.datetime.timedelta(days=offset)) }}
{% endmacro %}

{% macro _canada_christmas_observed(year) %}
    {% set christmas = dbt_holidates._date(year, 12, 25) %}
    {% if christmas.weekday() == 5 %}
        {{ return(christmas + modules.datetime.timedelta(days=2)) }}
    {% elif christmas.weekday() == 6 %}
        {{ return(christmas + modules.datetime.timedelta(days=2)) }}
    {% else %}
        {{ return(christmas) }}
    {% endif %}
{% endmacro %}

{% macro _canada_boxing_day_observed(year) %}
    {% set christmas = dbt_holidates._date(year, 12, 25) %}
    {% set boxing_day = dbt_holidates._date(year, 12, 26) %}
    {% if christmas.weekday() == 5 %}
        {{ return(boxing_day + modules.datetime.timedelta(days=2)) }}
    {% elif boxing_day.weekday() == 5 %}
        {{ return(boxing_day + modules.datetime.timedelta(days=2)) }}
    {% elif boxing_day.weekday() == 6 %}
        {{ return(boxing_day + modules.datetime.timedelta(days=1)) }}
    {% else %}
        {{ return(boxing_day) }}
    {% endif %}
{% endmacro %}

{% macro _qib_qingming(year) %}
    {% set year_in_century = (year | int) % 100 %}
    {% if (year | int) <= 2030 %}
        {% set day = (year_in_century * 0.2422 + 4.81) | int - (year_in_century // 4) %}
    {% else %}
        {% set day = (year_in_century * 0.2422 + 5.59) | int - (year_in_century // 4) %}
    {% endif %}
    {{ return(dbt_holidates._date(year, 4, day)) }}
{% endmacro %}
