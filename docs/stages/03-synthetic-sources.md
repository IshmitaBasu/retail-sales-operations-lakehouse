# Stage 3 — Synthetic source data and raw Delta tables

**Status:** Complete — 2 November 2026

## Purpose

Create deterministic initial and updated retail snapshots, validate them before writing, load the initial state into Databricks Delta seed tables, and declare tested dbt sources.

## Snapshot design

The generator supports:

```powershell
python scripts\generate_synthetic_data.py --snapshot initial
python scripts\generate_synthetic_data.py --snapshot updated
```

The initial snapshot contains 2,000 customers, 500 products, 20,000 orders, between 50,000 and 80,000 order lines, and eligible physical fulfilments through November 2025.

The updated snapshot deterministically adds 800 December 2025 orders, advances 250 existing physical orders through their lifecycle, and changes discounts on 100 existing order lines. A JSON manifest records row counts, file hashes, and affected business keys for the later incremental proof.

## Source files

| File | Grain |
|---|---|
| `customers.csv` | One row per customer |
| `products.csv` | One row per product |
| `orders.csv` | One row per order |
| `order_lines.csv` | One row per order line |
| `fulfilments.csv` | At most one row per eligible physical order |

## Generator checks

Before writing, the script validates:

- Primary-key uniqueness.
- Customer, order, product, and fulfilment relationships.
- Product type alignment with physical or digital orders.
- Positive quantities and valid discount bounds.
- One fulfilment per physical order.
- Delivered timestamp requirements.
- Fulfilment timestamp ordering.
- The agreed order-line volume boundary.

## Reproduce the initial raw load

From the repository root, with the Stage 2 environment and local Databricks profile configured:

```powershell
.\.venv\Scripts\Activate.ps1
python scripts\generate_synthetic_data.py --snapshot initial
dbt seed --profiles-dir .dbt --full-refresh
dbt test --profiles-dir .dbt --select "source:retail_raw.*"
```

`dbt seed` materializes the five CSV files as Delta tables in `workspace.retail_raw`. The `--full-refresh` flag is intentional for this raw demonstration snapshot; the incremental workflow is implemented and proved later in Stage 5.

To inspect the live row counts independently:

```sql
select 'customers' as table_name, count(*) as row_count from workspace.retail_raw.customers
union all select 'products', count(*) from workspace.retail_raw.products
union all select 'orders', count(*) from workspace.retail_raw.orders
union all select 'order_lines', count(*) from workspace.retail_raw.order_lines
union all select 'fulfilments', count(*) from workspace.retail_raw.fulfilments
order by table_name;
```

## Validation evidence

| Check | Result |
|---|---|
| Initial snapshot generated twice | Matching hashes for all five CSV files |
| Updated snapshot generated twice | Matching hashes for all five CSV files |
| Canonical folder state | `initial` |
| Raw seed load | 5 of 5 passed |
| Source test suite | 60 passed, 0 warned, 0 failed |

At Stage 3 completion, the initial Databricks counts reconciled exactly to `data/generated/snapshot_manifest.json`:

| Raw table | Manifest rows | Databricks rows |
|---|---:|---:|
| `customers` | 2,000 | 2,000 |
| `products` | 500 | 500 |
| `orders` | 20,000 | 20,000 |
| `order_lines` | 58,565 | 58,565 |
| `fulfilments` | 16,776 | 16,776 |

The initial files cover orders from 1 January 2024 through 30 November 2025. At this stage they remained canonical and the updated snapshot was deliberately reserved for the Stage 5 incremental proof. Stage 5 subsequently generated and retained the updated state, as documented in its stage report.

## Completion checklist

- [x] Implement deterministic initial and updated snapshot modes.
- [x] Add generator-side key, relationship, monetary, and timestamp validation.
- [x] Add explicit seed column types.
- [x] Add documented source declarations and generic source tests.
- [x] Prove repeatability for both snapshot modes.
- [x] Leave the canonical generated folder in the initial state.
- [x] Load the initial snapshot into raw Delta tables.
- [x] Run all source tests successfully.
- [x] Reconcile Databricks row counts with the manifest.

## Work log

- Generated the canonical initial snapshot with fixed seed `20261102`.
- Confirmed the initial and updated modes are byte-for-byte reproducible through SHA-256 comparison runs.
- Loaded all five source files into the raw Databricks schema with explicit dbt seed column types.
- Ran every declared source test successfully against the live Delta tables.
- Reconciled each raw table count independently to the checked-in manifest.
