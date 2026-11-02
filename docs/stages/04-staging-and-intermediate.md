# Stage 4 — Staging and intermediate transformations

**Status:** Complete — 2 November 2026

## Purpose

Transform the raw Delta sources into consistently typed, documented views while preserving source grain, then add reusable sales and fulfilment calculations for the later dimensional marts.

All Stage 4 relations are views. The raw tables remain unchanged, and the project does not yet claim an incremental fact or certified reporting layer.

## Staging models

| Model | Grain | Purpose | Stage 4 validation rows |
|---|---|---|---:|
| `view_customers` | One row per customer | Standardize customer segment, region, country code, dates, and timestamps | 2,000 |
| `view_products` | One row per product | Standardize text, product type, booleans, and two-decimal monetary types | 500 |
| `view_orders` | One row per order | Standardize order type, channel, lifecycle values, currency, and timestamps | 20,000 |
| `view_order_lines` | One row per order line | Standardize identifiers, quantity, monetary types, and update timestamp | 58,565 |
| `view_fulfilments` | One row per fulfilment/order | Standardize centre, carrier, status, event timestamps, and promise date | 16,776 |

Staging deliberately does not aggregate, impute missing lifecycle timestamps, or silently repair invalid business data. Invalid records must remain visible to tests.

## Intermediate models

### `view_order_line_enriched`

Grain: one row per order line. It joins staged orders, order lines, and products and calculates:

- Gross sales: `quantity × unit_price_eur`.
- Net sales: gross sales less the line discount.
- Cost: `quantity × unit_cost_eur`.
- Gross margin: net sales less cost.
- Recognized net sales: zero for cancelled orders, otherwise net sales.
- Incremental watermark: greatest of order and order-line update timestamps.

At Stage 4 completion its count was 58,565 rows, exactly matching `view_order_lines`. Stage 5 later advances both relations to the documented updated snapshot.

### `view_fulfilment_enriched`

Grain: one row per fulfilment/order. It joins staged fulfilments to orders and calculates:

- Hours from order creation to shipment.
- Hours from shipment to delivery.
- Delivered and cancelled indicators.
- On-time delivery for delivered records only.
- A combined record-update timestamp.

At Stage 4 completion its count was 16,776 rows, exactly matching `view_fulfilments`. Stage 5 later advances both relations to the documented updated snapshot.

## Run Stage 4

From the repository root, after completing Stages 2 and 3:

```powershell
.\.venv\Scripts\Activate.ps1
dbt build --profiles-dir .dbt --select tag:staging tag:intermediate
```

The selection builds the five staging views, then their tests, then the two dependent intermediate views and tests. dbt's dependency graph enforces that order automatically.

To rebuild only the views without tests:

```powershell
dbt run --profiles-dir .dbt --select tag:staging tag:intermediate
```

To rerun only the Stage 4 tests:

```powershell
dbt test --profiles-dir .dbt --select tag:staging tag:intermediate
```

## Data-quality coverage

The Stage 4 suite covers:

- Primary-key uniqueness and non-nullness at every declared grain.
- Order-to-customer, line-to-order, line-to-product, and fulfilment-to-order relationships.
- Accepted customer, product, order, payment, channel, currency, and fulfilment values.
- Positive quantity and non-negative monetary constraints.
- Discounts that do not exceed gross line sales.
- Exact gross-sales, net-sales, cost, margin, recognized-sales, and watermark formulas.
- Physical-only fulfilments, lifecycle timestamp ordering, delivery flags, and non-negative durations.
- Row-count reconciliation from each raw source to staging and from staging to intermediate.

## Validation evidence

The completed live build reported:

```text
117 data tests
7 view models
PASS=124 WARN=0 ERROR=0 SKIP=0 TOTAL=124
```

The full project currently contains 177 tests: 60 raw-source tests from Stage 3 and 117 Stage 4 tests. The unused `marts` configuration warning is expected because mart models begin in Stage 5.

## Completion checklist

- [x] Build five source-aligned staging views with `view_` names.
- [x] Preserve the declared source grains and reconcile row counts.
- [x] Normalize source fields without hiding invalid business data.
- [x] Build the order-line and fulfilment intermediate views.
- [x] Document all seven models and every exposed column.
- [x] Pass key, relationship, accepted-value, formula, timestamp, duration, and reconciliation tests.

## Work log

- Created five views in `workspace.retail_staging`.
- Created two views in `workspace.retail_intermediate`.
- Added model and column descriptions alongside generic dbt tests.
- Added four singular tests for numeric validity, monetary formulas, fulfilment logic, and row-count reconciliation.
- Built and tested the complete Stage 4 graph successfully against Databricks.
