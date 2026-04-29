{% macro _canada_holiday_rows(start_year, end_year) %}
    {% set rows = [] %}
    {% for year in range(start_year, end_year + 1) %}
        {% set calendar = "canada" %}
        {% set display = "Canadian Holidays" %}
        {% set country = "CA" %}
        {% set holiday_type = "federal_holiday" %}

        {% set actual = dbt_holidates._date(year, 1, 1) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_next_weekday(actual), "New Year's Day", holiday_type, "January 1, observed on next weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._good_friday(year), dbt_holidates._good_friday(year), "Good Friday", holiday_type, "Friday before Easter Sunday")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._easter_sunday(year) + modules.datetime.timedelta(days=1), dbt_holidates._easter_sunday(year) + modules.datetime.timedelta(days=1), "Easter Monday", holiday_type, "Monday after Easter Sunday")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._canada_victoria_day(year), dbt_holidates._canada_victoria_day(year), "Victoria Day", holiday_type, "Monday preceding May 25")) %}
        {% set actual = dbt_holidates._date(year, 7, 1) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_next_weekday(actual), "Canada Day", holiday_type, "July 1, observed on next weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 9, 0, 1), dbt_holidates._nth_weekday(year, 9, 0, 1), "Labour Day", holiday_type, "First Monday in September")) %}
        {% if year >= 2021 %}
            {% set actual = dbt_holidates._date(year, 9, 30) %}
            {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_next_weekday(actual), "National Day for Truth and Reconciliation", holiday_type, "September 30, federal statutory holiday since 2021")) %}
        {% endif %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 10, 0, 2), dbt_holidates._nth_weekday(year, 10, 0, 2), "Thanksgiving Day", holiday_type, "Second Monday in October")) %}
        {% set actual = dbt_holidates._date(year, 11, 11) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_next_weekday(actual), "Remembrance Day", holiday_type, "November 11, observed on next weekday when weekend")) %}
        {% set actual = dbt_holidates._date(year, 12, 25) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._canada_christmas_observed(year), "Christmas Day", holiday_type, "December 25, observed using Canadian federal next-weekday rules")) %}
        {% set actual = dbt_holidates._date(year, 12, 26) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._canada_boxing_day_observed(year), "Boxing Day", holiday_type, "December 26, observed using Canadian federal next-weekday rules")) %}
    {% endfor %}
    {{ return(rows) }}
{% endmacro %}
