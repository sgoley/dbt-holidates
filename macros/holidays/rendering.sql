{% macro _holiday_row(calendar_name, calendar_display_name, country_code, subdivision, holiday_date, observed_date, holiday_name, holiday_type, rule_description, is_observed=true) %}
    {{ return({
        "calendar_name": calendar_name,
        "calendar_display_name": calendar_display_name,
        "country_code": country_code,
        "subdivision": subdivision,
        "holiday_date": holiday_date,
        "observed_date": observed_date,
        "holiday_name": holiday_name,
        "holiday_type": holiday_type,
        "rule_description": rule_description,
        "is_observed": is_observed
    }) }}
{% endmacro %}

{% macro _render_holiday_rows(rows) %}
    {% if rows | length == 0 %}
        select
            cast(null as date) as holiday_date,
            cast(null as date) as observed_date,
            cast(null as {{ dbt.type_string() }}) as calendar_name,
            cast(null as {{ dbt.type_string() }}) as calendar_display_name,
            cast(null as {{ dbt.type_string() }}) as country_code,
            cast(null as {{ dbt.type_string() }}) as subdivision,
            cast(null as {{ dbt.type_string() }}) as holiday_name,
            cast(null as {{ dbt.type_string() }}) as holiday_type,
            cast(null as {{ dbt.type_boolean() }}) as is_observed,
            cast(null as {{ dbt.type_string() }}) as rule_description
        where 1 = 0
    {% else %}
        {% for row in rows | sort(attribute="calendar_name,observed_date,holiday_name") %}
            {% if not loop.first %}union all{% endif %}
            select
                cast('{{ row["holiday_date"].isoformat() }}' as date) as holiday_date,
                cast('{{ row["observed_date"].isoformat() }}' as date) as observed_date,
                '{{ row["calendar_name"] | replace("'", "''") }}' as calendar_name,
                '{{ row["calendar_display_name"] | replace("'", "''") }}' as calendar_display_name,
                '{{ row["country_code"] | replace("'", "''") }}' as country_code,
                {% if row["subdivision"] is none %}
                    cast(null as {{ dbt.type_string() }}) as subdivision,
                {% else %}
                    '{{ row["subdivision"] | replace("'", "''") }}' as subdivision,
                {% endif %}
                '{{ row["holiday_name"] | replace("'", "''") }}' as holiday_name,
                '{{ row["holiday_type"] | replace("'", "''") }}' as holiday_type,
                {% if row["is_observed"] %}true{% else %}false{% endif %} as is_observed,
                '{{ row["rule_description"] | replace("'", "''") }}' as rule_description
        {% endfor %}
    {% endif %}
{% endmacro %}
