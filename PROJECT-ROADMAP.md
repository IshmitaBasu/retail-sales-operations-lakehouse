# Retail Sales & Operations Analytics Lakehouse — Project Roadmap

This roadmap controls implementation order. A stage is complete only when its stated checks pass and its documentation reflects the implemented behavior.

## Stage 1 — Scope and architecture

- [x] Define business questions and portfolio boundary.
- [x] Define synthetic source entities and source grains.
- [x] Define staging, intermediate, dimension, and fact grains.
- [x] Define the Delta incremental strategy, unique key, and watermark.
- [x] Define sales and fulfilment rules.
- [x] Define the Power BI reporting boundary and security constraints.
- [x] Review and approve the architecture before implementation.

**Complete when:** the architecture is internally consistent and the user approves the fixed scope.

## Stage 2 — Local dbt and Databricks setup

- [x] Confirm the Databricks Free Edition catalog and writable schema permissions.
- [x] Create a Python virtual environment and pin compatible dbt packages.
- [x] Configure OAuth in a local `profiles.yml` outside Git.
- [x] Configure raw, staging, intermediate, and mart schemas.
- [x] Run `dbt debug`, `dbt parse`, and a trivial connection query.
- [x] Document setup and troubleshooting without exposing workspace details.

**Complete when:** dbt can execute against the Serverless Starter Warehouse and no credentials are versioned.

## Stage 3 — Synthetic source data and raw Delta tables

- [x] Implement deterministic initial and updated snapshot generation.
- [x] Validate keys, relationships, dates, statuses, and monetary constraints before writing CSVs.
- [x] Generate the five documented source files at the agreed scale.
- [x] Configure and load the raw Delta tables.
- [x] Add source declarations, descriptions, and source tests.
- [x] Prove that regeneration is deterministic.

**Complete when:** both snapshots are reproducible and the initial raw sources pass their tests.

## Stage 4 — Staging and intermediate transformations

- [x] Build five source-aligned staging views using the `view_` naming convention.
- [x] Normalize types and controlled values without changing source grain.
- [x] Build enriched order-line and fulfilment views.
- [x] Document every model and required column.
- [x] Test staging keys, relationships, and accepted values.

**Complete when:** staging and intermediate models build cleanly and preserve their declared grains.

## Stage 5 — Incremental transformation

- [x] Implement `fact_order_line` with Delta `merge`, `order_line_id`, and the documented watermark.
- [x] Run the initial full load and record the baseline.
- [x] Apply the updated deterministic snapshot.
- [x] Run the incremental model without a full refresh.
- [x] Prove expected inserts and updates occurred with no duplicate keys.
- [x] Add an incremental audit query or test.

**Complete when:** the second run updates and inserts only the intended business keys and all audit checks pass.

## Stage 6 — Dimensional marts and data quality

- [ ] Build four dimensions and `fact_order_fulfilment`.
- [ ] Add key, relationship, accepted-value, range, formula, timestamp, and reconciliation tests.
- [ ] Add focused unit tests for sales and fulfilment edge cases where supported.
- [ ] Run the complete `dbt build` successfully.
- [ ] Generate and review dbt documentation.

**Complete when:** all marts are documented, tested, and reconcile to staging.

## Stage 7 — Power BI reporting

- [ ] Connect Power BI Desktop to the Databricks SQL warehouse.
- [ ] Import only certified mart relations.
- [ ] Define documented DAX measures for the agreed KPIs.
- [ ] Build one report page with KPI, time-series, category, and fulfilment-centre views.
- [ ] Reconcile report values to independent Databricks SQL queries.
- [ ] Capture a credential-safe dashboard preview.

**Complete when:** the report is readable, filtered, reconciled, and exposes no connection secrets.

## Stage 8 — Final validation and portfolio polish

- [ ] Regenerate the project from documented inputs and commands.
- [ ] Run the full dbt build, documentation generation, and incremental proof.
- [ ] Scan the repository for credentials, personal details, generated artifacts, and broken links.
- [ ] Complete the README with architecture, setup, validation results, dashboard preview, limitations, and cleanup guidance.
- [ ] Add accurate completed-project CV wording.
- [ ] Review the complete Git diff and prepare the final commit.

**Complete when:** another person can understand the project, reproduce the transformation workflow, and see an honest portfolio demonstration.
