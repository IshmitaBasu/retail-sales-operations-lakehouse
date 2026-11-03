# Stage 6 — Dimensional marts and data quality

**Status:** Complete — 2 November 2026

## Purpose

Complete the certified reporting layer with a small star schema, validate every declared grain and relationship, exercise business logic with isolated fixtures, and generate browsable dbt documentation and lineage.

All certified models are physical Delta tables in `workspace.retail_marts`. Power BI will connect only to this schema in Stage 7.

## Certified mart inventory

| Model | Grain | Materialization | Live rows |
|---|---|---|---:|
| `dim_customer` | One row per customer | Table | 2,000 |
| `dim_product` | One row per product | Table | 500 |
| `dim_date` | One row per calendar date | Table | 1,096 |
| `dim_fulfilment_centre` | One row per fulfilment centre | Table | 4 |
| `fact_order_line` | One row per order line | Incremental Delta table | 60,929 |
| `fact_order_fulfilment` | One row per physical-order fulfilment | Table | 17,446 |

## Dimension design

### `dim_customer`

Uses `customer_id` as its natural primary key and exposes signup date, customer segment, region, country, and source-update timestamp.

### `dim_product`

Uses `product_id` as its natural primary key and exposes name, category, physical/digital type, unit cost, list price, active status, and source-update timestamp.

### `dim_fulfilment_centre`

Uses `fulfilment_centre_id` as its natural primary key. A dedicated consistency test ensures that every centre ID maps to exactly one name and region before the distinct dimension is accepted.

### `dim_date`

Uses `date_day` as its primary key and includes an integer `date_key`, calendar labels, sortable year-month, week and weekday attributes, period-start dates, and a weekend flag.

The generated spine covers 1 January 2024 through 31 December 2026. The final full year is included because December 2025 orders can have promise or delivery events in January 2026. A singular test proves the spine is contiguous, starts on 1 January, ends on 31 December, and has the correct inclusive row count.

## Fact design

### `fact_order_line`

The Stage 5 incremental sales fact now relates its customer, product, and order-date foreign keys to the certified dimensions rather than the staging layer. Its grain and Delta merge behavior are unchanged.

### `fact_order_fulfilment`

This physical fact contains one row per fulfilment and at most one row per physical order. It exposes:

- Order, customer, centre, and event-date keys.
- Order and fulfilment lifecycle statuses.
- Carrier and operational timestamps.
- Hours from order creation to shipment.
- Hours from shipment to delivery.
- Delivered, cancelled, and on-time-delivery indicators.
- Source update timestamps for auditability.

## Test strategy

The complete project contains 290 data tests:

- Generic uniqueness and non-null tests for every declared primary key.
- Fact-to-dimension and source relationship tests.
- Accepted-value tests for controlled business fields.
- Numeric, formula, timestamp-ordering, duration, and delivery-flag rules.
- Exact source-to-fact value reconciliation.
- Raw-to-staging, staging-to-intermediate, and intermediate-to-mart row reconciliation.
- Incremental source-to-fact reconciliation and duplicate prevention.
- Date-spine continuity and fulfilment-centre consistency.

Two isolated dbt unit tests use small fixtures to prove logic independently of the generated dataset:

1. Gross sales, net sales, cost, margin, and zero recognized sales for a cancelled order.
2. Fulfilment and delivery durations, an on-time delivered record, and null delivery metrics for an in-progress record.

Both unit tests passed individually and again inside the complete build.

## Run and validate Stage 6

From the repository root:

```powershell
.\.venv\Scripts\Activate.ps1

# Build and test only the certified mart layer.
dbt build --profiles-dir .dbt --select tag:marts

# Run isolated business-logic unit tests.
dbt test --profiles-dir .dbt --select "test_type:unit"

# Reconstruct and validate the complete project graph.
dbt build --profiles-dir .dbt

# Generate and preview model documentation and lineage.
dbt docs generate --profiles-dir .dbt
dbt docs serve --profiles-dir .dbt
```

The complete build result was:

```text
1 incremental model
5 seeds
5 table models
7 view models
290 data tests
2 unit tests
PASS=310 WARN=0 ERROR=0 SKIP=0 TOTAL=310
```

`dbt docs generate` successfully wrote the local catalog and site artifacts under the ignored `target/` directory. The Databricks adapter emitted non-fatal warnings about optional owner/comment metadata columns while generating the catalog; model, column, test, and lineage metadata were still generated successfully.

## Completion checklist

- [x] Build four physical dimensions with explicit grains and natural keys.
- [x] Build the physical fulfilment fact at one row per fulfilment/order.
- [x] Connect both facts to certified dimensions with relationship tests.
- [x] Document every model and exposed column.
- [x] Add mart key, relationship, accepted-value, range, formula, timestamp, and reconciliation tests.
- [x] Add and pass two isolated business-logic unit tests.
- [x] Pass the mart-only build with 118 successful tasks.
- [x] Pass the complete end-to-end build with 310 successful tasks.
- [x] Generate and review dbt documentation and lineage artifacts.
