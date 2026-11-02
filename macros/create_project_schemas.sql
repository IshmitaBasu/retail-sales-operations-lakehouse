{% macro create_project_schemas() %}
    {% set project_schemas = [
        'retail_raw',
        'retail_staging',
        'retail_intermediate',
        'retail_marts'
    ] %}

    {% for schema_name in project_schemas %}
        {% set create_schema_sql %}
            create schema if not exists
                {{ adapter.quote(target.catalog) }}.{{ adapter.quote(schema_name) }}
        {% endset %}

        {% do run_query(create_schema_sql) %}
        {{ log('Confirmed schema ' ~ target.catalog ~ '.' ~ schema_name, info=true) }}
    {% endfor %}
{% endmacro %}
