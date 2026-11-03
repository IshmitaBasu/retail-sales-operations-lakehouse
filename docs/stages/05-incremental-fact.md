# Stage 5 — Incremental order-line fact

**Status:** Complete — 2 November 2026

## Purpose

Build `fact_order_line` as a physical Delta table and prove that a normal dbt incremental run inserts new business keys and updates changed existing keys without recreating the table or producing duplicates.

## Model contract

| Property | Implementation |
|---|---|
| Relation | `workspace.retail_marts.fact_order_line` |
| Grain | One row per order line |
| Materialization | dbt incremental Delta table |
| Incremental strategy | `merge` |
| Unique key | `order_line_id` |
| High watermark | Greatest of order and order-line `updated_at` |
| Late-arriving insert safeguard | Include any source key not already present in the fact |
| Schema-change behavior | Fail visibly |

The unseen-key check matters because the initial data has lifecycle updates through 8 December 2025, while a newly received December order can have an earlier update timestamp. A pure global-watermark filter would miss that valid new business key. Existing keys still require a newer watermark; unseen keys are included regardless of watermark and merged by `order_line_id`.

## Reproduce the incremental proof

Run these commands from the repository root after completing Stage 4:

```powershell
.\.venv\Scripts\Activate.ps1

# Establish the initial source state and baseline fact.
python scripts\generate_synthetic_data.py --snapshot initial
dbt seed --profiles-dir .dbt --full-refresh
dbt run --profiles-dir .dbt --select +fact_order_line --full-refresh

# Replace only the raw source state; do not rebuild the fact yet.
python scripts\generate_synthetic_data.py --snapshot updated
dbt seed --profiles-dir .dbt --full-refresh

# Measure the expected fact differences before the merge.
dbt show --profiles-dir .dbt --select stage5_incremental_audit

# Execute the actual incremental Delta merge.
dbt run --profiles-dir .dbt --select fact_order_line

# Prove that the source and fact now reconcile.
dbt show --profiles-dir .dbt --select stage5_incremental_audit
dbt build --profiles-dir .dbt
```

The baseline uses `dbt run`, rather than a fact-only `dbt build`, because the current project also contains a Stage 6 cross-mart reconciliation test. During the intentional initial-versus-updated transition, the other fact may temporarily represent a different snapshot. The final complete `dbt build` recreates all marts on the updated state and runs every test together.

The final repository state intentionally retains the updated snapshot so later marts and reporting include December 2025.

## Initial baseline

The full-refresh baseline produced:

| Measure | Result |
|---|---:|
| Fact rows | 58,565 |
| Distinct `order_line_id` values | 58,565 |
| Recognized net sales | €26,725,346.81 |
| Fact-specific build tasks | 34 passed, 0 failed |

The initial maximum watermark falls on 8 December 2025 because late-November orders can receive later lifecycle updates.

## Controlled update

The deterministic updated snapshot contains:

| Change | Count |
|---|---:|
| Added orders | 800 |
| Advanced existing orders | 250 |
| Directly modified existing order lines | 100 |
| Resulting new order lines | 2,364 |
| Existing fact rows whose values must change | 836 |

The 836 changed fact rows include every line affected by an advanced parent order plus the directly changed lines. The saved pre-merge audit returned:

```text
source_rows=60929
fact_rows=58565
missing_in_fact=2364
unexpected_in_fact=0
changed_existing_rows=836
duplicate_key_groups=0
```

## Delta merge evidence

The model was run with `dbt run --select fact_order_line` and without `--full-refresh`. Delta table history recorded a `MERGE` with:

```text
numSourceRows=3200
numTargetRowsInserted=2364
numTargetRowsUpdated=836
numTargetRowsDeleted=0
```

The processed source count reconciles exactly: `2,364 inserts + 836 updates = 3,200 rows`.

## Post-merge validation

The same saved audit after the merge returned:

```text
source_rows=60929
fact_rows=60929
missing_in_fact=0
unexpected_in_fact=0
changed_existing_rows=0
duplicate_key_groups=0
```

Final fact measures:

| Measure | Result |
|---|---:|
| Fact rows | 60,929 |
| Distinct `order_line_id` values | 60,929 |
| Recognized net sales | €27,793,501.80 |

The complete project suite passed on the updated state:

```text
PASS=210 WARN=0 ERROR=0 SKIP=0 TOTAL=210
```

## Audit assets

- `analyses/stage5_incremental_audit.sql` reports source rows, fact rows, missing keys, unexpected keys, stale existing rows, and duplicate key groups.
- `tests/assert_fact_order_line_reconciles.sql` fails if any key or fact value differs from the current enriched source.
- Generic tests enforce the fact key, relationships, required fields, and controlled values.

## Completion checklist

- [x] Create a physical incremental Delta fact using `merge`.
- [x] Use `order_line_id` as the unique merge key.
- [x] Filter changed existing rows with the documented watermark.
- [x] Protect against late-arriving unseen keys.
- [x] Record and test the 58,565-row initial baseline.
- [x] Load the deterministic updated raw snapshot.
- [x] Measure 2,364 expected inserts and 836 expected updates before the run.
- [x] Execute the incremental model without a full refresh.
- [x] Confirm Delta history reports the expected insert and update counts.
- [x] Reconcile all 60,929 final fact rows with zero duplicates or stale values.
- [x] Pass all 210 project tests.
