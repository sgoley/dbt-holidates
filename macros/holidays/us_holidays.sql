{% macro _us_government_holiday_rows(start_year, end_year) %}
    {% set rows = [] %}
    {% for year in range(start_year, end_year + 1) %}
        {% set calendar = "us_government" %}
        {% set display = "US Government Holidays" %}
        {% set country = "US" %}
        {% set holiday_type = "federal_holiday" %}

        {% set actual = dbt_holidates._date(year, 1, 1) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_weekday(actual), "New Year's Day", holiday_type, "January 1, observed on adjacent weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 1, 0, 3), dbt_holidates._nth_weekday(year, 1, 0, 3), "Martin Luther King Jr. Day", holiday_type, "Third Monday in January")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 2, 0, 3), dbt_holidates._nth_weekday(year, 2, 0, 3), "Washington's Birthday", holiday_type, "Third Monday in February")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._last_weekday(year, 5, 0), dbt_holidates._last_weekday(year, 5, 0), "Memorial Day", holiday_type, "Last Monday in May")) %}
        {% if year >= 2021 %}
            {% set actual = dbt_holidates._date(year, 6, 19) %}
            {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_weekday(actual), "Juneteenth National Independence Day", holiday_type, "June 19, observed on adjacent weekday when weekend")) %}
        {% endif %}
        {% set actual = dbt_holidates._date(year, 7, 4) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_weekday(actual), "Independence Day", holiday_type, "July 4, observed on adjacent weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 9, 0, 1), dbt_holidates._nth_weekday(year, 9, 0, 1), "Labor Day", holiday_type, "First Monday in September")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 10, 0, 2), dbt_holidates._nth_weekday(year, 10, 0, 2), "Columbus Day", holiday_type, "Second Monday in October")) %}
        {% set actual = dbt_holidates._date(year, 11, 11) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_weekday(actual), "Veterans Day", holiday_type, "November 11, observed on adjacent weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, dbt_holidates._nth_weekday(year, 11, 3, 4), dbt_holidates._nth_weekday(year, 11, 3, 4), "Thanksgiving Day", holiday_type, "Fourth Thursday in November")) %}
        {% set actual = dbt_holidates._date(year, 12, 25) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, none, actual, dbt_holidates._observed_weekday(actual), "Christmas Day", holiday_type, "December 25, observed on adjacent weekday when weekend")) %}
    {% endfor %}
    {{ return(rows) }}
{% endmacro %}

{% macro _us_bank_holiday_rows(start_year, end_year) %}
    {% set rows = [] %}
    {% for row in dbt_holidates._us_government_holiday_rows(start_year, end_year) %}
        {% do rows.append(dbt_holidates._holiday_row("us_bank", "US Bank Holidays", row["country_code"], row["subdivision"], row["holiday_date"], row["observed_date"], row["holiday_name"], "bank_holiday", row["rule_description"], row["is_observed"])) %}
    {% endfor %}
    {{ return(rows) }}
{% endmacro %}

{% macro _us_market_holiday_rows(start_year, end_year) %}
    {% set rows = [] %}
    {% for year in range(start_year, end_year + 1) %}
        {% set calendar = "us_market" %}
        {% set display = "US Market Holidays" %}
        {% set country = "US" %}
        {% set holiday_type = "market_holiday" %}

        {% set actual = dbt_holidates._date(year, 1, 1) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", actual, dbt_holidates._observed_weekday(actual), "New Year's Day", holiday_type, "January 1, observed on adjacent weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._nth_weekday(year, 1, 0, 3), dbt_holidates._nth_weekday(year, 1, 0, 3), "Martin Luther King Jr. Day", holiday_type, "Third Monday in January")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._nth_weekday(year, 2, 0, 3), dbt_holidates._nth_weekday(year, 2, 0, 3), "Washington's Birthday", holiday_type, "Third Monday in February")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._good_friday(year), dbt_holidates._good_friday(year), "Good Friday", holiday_type, "Friday before Easter Sunday")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._last_weekday(year, 5, 0), dbt_holidates._last_weekday(year, 5, 0), "Memorial Day", holiday_type, "Last Monday in May")) %}
        {% if year >= 2022 %}
            {% set actual = dbt_holidates._date(year, 6, 19) %}
            {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", actual, dbt_holidates._observed_weekday(actual), "Juneteenth National Independence Day", holiday_type, "June 19, observed by NYSE beginning in 2022")) %}
        {% endif %}
        {% set actual = dbt_holidates._date(year, 7, 4) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", actual, dbt_holidates._observed_weekday(actual), "Independence Day", holiday_type, "July 4, observed on adjacent weekday when weekend")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._nth_weekday(year, 9, 0, 1), dbt_holidates._nth_weekday(year, 9, 0, 1), "Labor Day", holiday_type, "First Monday in September")) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", dbt_holidates._nth_weekday(year, 11, 3, 4), dbt_holidates._nth_weekday(year, 11, 3, 4), "Thanksgiving Day", holiday_type, "Fourth Thursday in November")) %}
        {% set actual = dbt_holidates._date(year, 12, 25) %}
        {% do rows.append(dbt_holidates._holiday_row(calendar, display, country, "NYSE", actual, dbt_holidates._observed_weekday(actual), "Christmas Day", holiday_type, "December 25, observed on adjacent weekday when weekend")) %}
    {% endfor %}

    {% set special_closures = {
        "2001-09-11": "September 11 market closure",
        "2001-09-12": "September 11 market closure",
        "2001-09-13": "September 11 market closure",
        "2001-09-14": "September 11 market closure",
        "2004-06-11": "National Day of Mourning for Ronald Reagan",
        "2007-01-02": "National Day of Mourning for Gerald Ford",
        "2012-10-29": "Hurricane Sandy market closure",
        "2012-10-30": "Hurricane Sandy market closure",
        "2018-12-05": "National Day of Mourning for George H. W. Bush",
        "2025-01-09": "National Day of Mourning for Jimmy Carter"
    } %}
    {% for date_string, name in special_closures.items() %}
        {% set year = date_string[0:4] | int %}
        {% if year >= start_year and year <= end_year %}
            {% set closure_date = modules.datetime.date.fromisoformat(date_string) %}
            {% do rows.append(dbt_holidates._holiday_row("us_market", "US Market Holidays", "US", "NYSE", closure_date, closure_date, name, "market_closure", "Historical full-day NYSE closure", true)) %}
        {% endif %}
    {% endfor %}
    {{ return(rows) }}
{% endmacro %}
