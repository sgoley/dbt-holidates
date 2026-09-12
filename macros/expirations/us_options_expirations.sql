{% macro _options_expiration_row(expiration_date, scheduled_date, contract_month, product_type, cycle_type, is_holiday_rolled, roll_reason, is_quad_witching, is_vix_inversion, days_to_equity_monthly_opex) %}
    {{ return({
        "expiration_date": expiration_date,
        "scheduled_date": scheduled_date,
        "contract_month": contract_month,
        "product_type": product_type,
        "cycle_type": cycle_type,
        "is_holiday_rolled": is_holiday_rolled,
        "roll_reason": roll_reason,
        "is_quad_witching": is_quad_witching,
        "is_vix_inversion": is_vix_inversion,
        "days_to_equity_monthly_opex": days_to_equity_monthly_opex
    }) }}
{% endmacro %}

{% macro _us_options_expiration_rows(start_year, end_year, product_types=none) %}
    {% set rows = [] %}

    {# 1. Build cache of market closures covering start_year - 1 through end_year + 1 #}
    {% set market_closed_dates = [] %}
    {% set market_closed_dict = {} %}
    {% for row in dbt_holidates._us_market_holiday_rows(start_year - 1, end_year + 1) %}
        {% do market_closed_dates.append(row["observed_date"]) %}
        {% do market_closed_dict.update({row["observed_date"]: row["holiday_name"]}) %}
    {% endfor %}

    {% for year in range(start_year, end_year + 1) %}
        {% for month in range(1, 13) %}
            {% set contract_month = "%04d-%02d" | format(year, month) %}

            {# --- A. Equity & Index Monthly OPEX (3rd Friday) --- #}
            {% set equity_sched = dbt_holidates._nth_weekday(year, month, 4, 3) %}
            {% set equity_actual = dbt_holidates._roll_backward_to_trading_day(equity_sched, market_closed_dates) %}
            {% set is_equity_rolled = (equity_actual != equity_sched) %}
            {% set equity_roll_reason = none %}
            {% if is_equity_rolled %}
                {% set holiday_name = market_closed_dict.get(equity_sched, "Market Holiday/Closure") %}
                {% set equity_roll_reason = "Scheduled 3rd Friday fell on " ~ holiday_name ~ "; rolled backward to preceding trading day" %}
            {% endif %}
            {% set is_quad = (month in [3, 6, 9, 12]) %}

            {% if product_types is none or 'equity_monthly' in product_types %}
                {% do rows.append(dbt_holidates._options_expiration_row(
                    equity_actual,
                    equity_sched,
                    contract_month,
                    "equity_monthly",
                    "quarterly" if is_quad else "monthly",
                    is_equity_rolled,
                    equity_roll_reason,
                    is_quad,
                    false,
                    0
                )) %}
            {% endif %}

            {# --- B. Equity Weekly OPEX (All other Fridays in the month) --- #}
            {% if product_types is none or 'equity_weekly' in product_types %}
                {% for occurrence in range(1, 6) %}
                    {% set fri_candidate = dbt_holidates._nth_weekday(year, month, 4, occurrence) %}
                    {# Only consider if still in the same calendar month and not the 3rd Friday #}
                    {% if fri_candidate.month == month and occurrence != 3 %}
                        {% set weekly_actual = dbt_holidates._roll_backward_to_trading_day(fri_candidate, market_closed_dates) %}
                        {% set is_weekly_rolled = (weekly_actual != fri_candidate) %}
                        {% set weekly_roll_reason = none %}
                        {% if is_weekly_rolled %}
                            {% set holiday_name = market_closed_dict.get(fri_candidate, "Market Holiday/Closure") %}
                            {% set weekly_roll_reason = "Scheduled Friday fell on " ~ holiday_name ~ "; rolled backward to preceding trading day" %}
                        {% endif %}
                        {% do rows.append(dbt_holidates._options_expiration_row(
                            weekly_actual,
                            fri_candidate,
                            contract_month,
                            "equity_weekly",
                            "weekly",
                            is_weekly_rolled,
                            weekly_roll_reason,
                            false,
                            false,
                            (weekly_actual - equity_actual).days
                        )) %}
                    {% endif %}
                {% endfor %}
            {% endif %}

            {# --- C. End-of-Month (EOM) & End-of-Quarter (EOQ) Index Options --- #}
            {% set is_eoq = (month in [3, 6, 9, 12]) %}
            {% set p_type = "index_eoq" if is_eoq else "index_eom" %}
            {% if product_types is none or p_type in product_types or 'index_eom' in product_types %}
                {% set last_cal_day = dbt_holidates._last_day_of_month(year, month) %}
                {% set eom_actual = dbt_holidates._roll_backward_to_trading_day(last_cal_day, market_closed_dates) %}
                {% set is_eom_rolled = (eom_actual != last_cal_day) %}
                {% set eom_roll_reason = none %}
                {% if is_eom_rolled %}
                    {% set holiday_name = market_closed_dict.get(last_cal_day, "Weekend/Closure") %}
                    {% set eom_roll_reason = "Month-end calendar date fell on " ~ holiday_name ~ "; rolled backward to preceding business day" %}
                {% endif %}
                {% do rows.append(dbt_holidates._options_expiration_row(
                    eom_actual,
                    last_cal_day,
                    contract_month,
                    p_type,
                    "quarterly" if is_eoq else "monthly",
                    is_eom_rolled,
                    eom_roll_reason,
                    false,
                    false,
                    (eom_actual - equity_actual).days
                )) %}
            {% endif %}

            {# --- D. CBOE VIX Monthly Expiration & Inversion Detection --- #}
            {% if product_types is none or 'vix_monthly' in product_types %}
                {% set next_year = year + 1 if month == 12 else year %}
                {% set next_month = 1 if month == 12 else month + 1 %}
                {% set next_spx_sched = dbt_holidates._nth_weekday(next_year, next_month, 4, 3) %}
                {% set next_spx_actual = dbt_holidates._roll_backward_to_trading_day(next_spx_sched, market_closed_dates) %}

                {# CBOE rule: 30 days prior to subsequent month SPX settlement #}
                {% set vix_sched = next_spx_actual - modules.datetime.timedelta(days=30) %}
                {% set vix_actual = dbt_holidates._roll_backward_to_trading_day(vix_sched, market_closed_dates) %}
                {% set is_vix_rolled = (vix_actual != vix_sched) %}
                {% set vix_roll_reason = none %}
                {% if is_vix_rolled %}
                    {% set holiday_name = market_closed_dict.get(vix_sched, "Market Holiday/Closure") %}
                    {% set vix_roll_reason = "Target 30-day prior settlement date fell on " ~ holiday_name ~ "; rolled backward to preceding business day" %}
                {% endif %}

                {% set diff_days = (vix_actual - equity_actual).days %}
                {% set is_inversion = (diff_days < 0) %}

                {% do rows.append(dbt_holidates._options_expiration_row(
                    vix_actual,
                    vix_sched,
                    contract_month,
                    "vix_monthly",
                    "monthly",
                    is_vix_rolled,
                    vix_roll_reason,
                    false,
                    is_inversion,
                    diff_days
                )) %}
            {% endif %}

        {% endfor %}
    {% endfor %}

    {{ return(rows) }}
{% endmacro %}

{% macro _render_options_expiration_rows(rows) %}
    {% if rows | length == 0 %}
        select
            cast(null as date) as expiration_date,
            cast(null as date) as scheduled_date,
            cast(null as {{ dbt.type_string() }}) as contract_month,
            cast(null as {{ dbt.type_string() }}) as product_type,
            cast(null as {{ dbt.type_string() }}) as cycle_type,
            cast(null as {{ dbt.type_boolean() }}) as is_holiday_rolled,
            cast(null as {{ dbt.type_string() }}) as roll_reason,
            cast(null as {{ dbt.type_boolean() }}) as is_quad_witching,
            cast(null as {{ dbt.type_boolean() }}) as is_vix_inversion,
            cast(null as {{ dbt.type_int() }}) as days_to_equity_monthly_opex
        where 1 = 0
    {% else %}
        {% for row in rows | sort(attribute="expiration_date,product_type") %}
            {% if loop.first %}
            select
                cast('{{ row["expiration_date"].isoformat() }}' as date) as expiration_date,
                cast('{{ row["scheduled_date"].isoformat() }}' as date) as scheduled_date,
                '{{ row["contract_month"] }}' as contract_month,
                '{{ row["product_type"] }}' as product_type,
                '{{ row["cycle_type"] }}' as cycle_type,
                {% if row["is_holiday_rolled"] %}true{% else %}false{% endif %} as is_holiday_rolled,
                {% if row["roll_reason"] is none %}cast(null as {{ dbt.type_string() }}){% else %}'{{ dbt.escape_single_quotes(row["roll_reason"]) }}'{% endif %} as roll_reason,
                {% if row["is_quad_witching"] %}true{% else %}false{% endif %} as is_quad_witching,
                {% if row["is_vix_inversion"] %}true{% else %}false{% endif %} as is_vix_inversion,
                {% if row["days_to_equity_monthly_opex"] is none %}cast(null as {{ dbt.type_int() }}){% else %}cast({{ row["days_to_equity_monthly_opex"] }} as {{ dbt.type_int() }}){% endif %} as days_to_equity_monthly_opex
            {% else %}
            union all select date '{{ row["expiration_date"].isoformat() }}', date '{{ row["scheduled_date"].isoformat() }}', '{{ row["contract_month"] }}', '{{ row["product_type"] }}', '{{ row["cycle_type"] }}', {% if row["is_holiday_rolled"] %}true{% else %}false{% endif %}, {% if row["roll_reason"] is none %}null{% else %}'{{ dbt.escape_single_quotes(row["roll_reason"]) }}'{% endif %}, {% if row["is_quad_witching"] %}true{% else %}false{% endif %}, {% if row["is_vix_inversion"] %}true{% else %}false{% endif %}, {% if row["days_to_equity_monthly_opex"] is none %}null{% else %}{{ row["days_to_equity_monthly_opex"] }}{% endif %}
            {% endif %}
        {% endfor %}
    {% endif %}
{% endmacro %}

{% macro get_options_expirations(start_year=none, end_year=none, product_types=none) %}
    {% set start_year = (start_year if start_year is not none else var("dbt_holidates_start_year", 2000)) | int %}
    {% set end_year = (end_year if end_year is not none else var("dbt_holidates_end_year", 2035)) | int %}

    {% if end_year < start_year %}
        {{ exceptions.raise_compiler_error("dbt_holidates.get_options_expirations end_year must be greater than or equal to start_year") }}
    {% endif %}

    {{ dbt_holidates._render_options_expiration_rows(dbt_holidates._us_options_expiration_rows(start_year, end_year, product_types)) }}
{% endmacro %}
