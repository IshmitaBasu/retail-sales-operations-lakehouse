# Stage 1 — Scope and architecture

**Status:** Complete — architecture approved November 2, 2026

## Purpose

Fix a small, achievable project boundary before configuring Databricks or implementing dbt models.

## Decisions

- Use only deterministic synthetic retail data.
- Cover customers, products, orders, order lines, and fulfilments from January 2024 through December 2025.
- Build five staging views, two intermediate views, four dimensions, and two facts.
- Demonstrate one genuine incremental Delta `merge` in `fact_order_line`.
- Simulate inserts and updates through deterministic initial and updated source snapshots.
- Use Power BI Desktop over certified marts only. The initial single-page boundary was expanded during Stage 7 to four focused pages so the project can demonstrate report navigation and a broader set of Power BI skills without expanding the data-model scope.
- Exclude production ingestion, orchestration, SCDs, streaming, forecasting, and Power BI Service publication.
- Use Databricks Free Edition and the included Serverless Starter Warehouse.

## Review checklist

- [x] Source grains are explicit.
- [x] Fact and dimension grains are explicit.
- [x] The incremental key, watermark, and expected behavior are explicit.
- [x] Sales and fulfilment formulas are defined.
- [x] Testing and reporting boundaries are defined.
- [x] Security and cost limits are defined.
- [x] User approves the architecture and authorizes Stage 2.

The full design contract is [the architecture document](../architecture.md).
