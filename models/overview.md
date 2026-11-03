{% docs __overview__ %}

# Retail Sales & Operations Analytics Lakehouse

This portfolio project transforms deterministic synthetic retail data into a tested dimensional mart on Databricks Delta Lake.

## Data flow

1. Five raw Delta seed tables represent customers, products, orders, order lines, and fulfilments.
2. Five staging views standardize source types and controlled values without changing grain.
3. Two intermediate views calculate reusable sales and fulfilment logic.
4. Four dimensions and two facts form the certified reporting layer in `retail_marts`.
5. `fact_order_line` uses a Delta `merge` to update only new or changed business keys.

## Certified reporting models

- `dim_customer`
- `dim_product`
- `dim_date`
- `dim_fulfilment_centre`
- `fact_order_line`
- `fact_order_fulfilment`

Every model and column documents its grain and meaning. Generic, singular, reconciliation, and unit tests protect keys, relationships, formulas, lifecycle rules, and incremental behavior.

This is a portfolio-scale learning implementation using only synthetic data. It is not a production retail platform.

{% enddocs %}
