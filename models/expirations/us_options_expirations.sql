{{ config(materialized=var('dbt_holidates_expirations_materialized', 'table')) }}

{{ dbt_holidates.get_options_expirations() }}

