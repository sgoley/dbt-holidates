{% macro _last_day_of_month(year, month) %}
    {% if (month | int) == 12 %}
        {% set next_month = dbt_holidates._date((year | int) + 1, 1, 1) %}
    {% else %}
        {% set next_month = dbt_holidates._date(year, (month | int) + 1, 1) %}
    {% endif %}
    {{ return(next_month - modules.datetime.timedelta(days=1)) }}
{% endmacro %}

{% macro _roll_backward_to_trading_day(target_date, holiday_dates_set) %}
    {% set ns = namespace(found_date=none, found=false) %}
    {% for offset in range(0, 10) %}
        {% if not ns.found %}
            {% set check_date = target_date - modules.datetime.timedelta(days=offset) %}
            {% if check_date.weekday() < 5 and check_date not in holiday_dates_set %}
                {% set ns.found_date = check_date %}
                {% set ns.found = true %}
            {% endif %}
        {% endif %}
    {% endfor %}
    {{ return(ns.found_date) }}
{% endmacro %}
