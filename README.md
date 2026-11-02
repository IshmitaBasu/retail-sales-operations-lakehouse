# Retail Sales & Operations Analytics Lakehouse

> **Status:** Stages 1–5 complete; the remaining dimensions and fulfilment fact are next.

A small analytics-engineering portfolio project using synthetic retail order, product, customer, and fulfilment data. The project will demonstrate dbt transformations on Databricks Delta tables, one verified incremental `MERGE` workflow, tested dimensional marts, generated documentation, and a Power BI Desktop report over certified models.

This is a non-commercial learning project built on Databricks Free Edition. It is not a production retail, finance, inventory, or fulfilment system and contains no real customer data.

## Business questions

The first release will answer:

1. How are gross sales, net sales, order count, units sold, and average order value changing over time?
2. Which product categories and products contribute most to sales?
3. What share of orders is cancelled, delivered on time, or delivered late?
4. How do fulfilment time and on-time performance vary by fulfilment centre?

## Planned deliverables

- Deterministic synthetic retail source data.
- Raw Delta tables in Databricks.
- Documented dbt staging views.
- A verified incremental order-line transformation using Delta `MERGE`.
- Four dimensions and two fact tables with explicit grains.
- Schema, uniqueness, relationship, accepted-value, business-rule, and reconciliation tests.
- Generated dbt documentation.
- A one-page Power BI Desktop report using only certified marts.
- Reproducible setup, validation, security, and limitation notes.

## Architecture

```mermaid
flowchart LR
    G[Python synthetic-data generator] --> C[Versioned CSV snapshots]
    C --> R[(Databricks raw Delta tables)]
    R --> S[dbt staging views]
    S --> I[dbt intermediate models]
    I --> M[(Certified dimensions and facts)]
    M --> P[Power BI Desktop]
```

The detailed design contract is in [docs/architecture.md](./docs/architecture.md). The implementation order and completion criteria are in [PROJECT-ROADMAP.md](./PROJECT-ROADMAP.md).

## Technology

- Python 3.11 for deterministic synthetic-data generation.
- dbt Core with the `dbt-databricks` adapter.
- Databricks Free Edition, Unity Catalog, Delta Lake, and a serverless SQL warehouse.
- Power BI Desktop in Import mode.
- Git and GitHub for version control and portfolio documentation.

## Security boundary

- Databricks OAuth will be used for local development where possible.
- `profiles.yml`, `.databrickscfg`, access tokens, workspace hostnames, and SQL warehouse paths must remain outside Git.
- Power BI working `.pbix` files are ignored until a final credential and connection review. A safe screenshot and, if practical, a `.pbit` template will be used for the portfolio.
- Only synthetic data is permitted.

## Repository structure

```text
data/generated/       Deterministic synthetic CSV snapshots
docs/                 Architecture, stage reports, and safe images
models/staging/       Source-aligned dbt views
models/intermediate/  Reusable transformation logic
models/marts/         Certified dimensions and facts
powerbi/              Sanitized report artifacts
scripts/              Data-generation and validation utilities
tests/                Singular dbt business-rule tests
```

## Current validation

Stage 3 created and loaded the initial deterministic snapshot into five Delta tables in `workspace.retail_raw`:

| Raw table | Rows |
|---|---:|
| `customers` | 2,000 |
| `products` | 500 |
| `orders` | 20,000 |
| `order_lines` | 58,565 |
| `fulfilments` | 16,776 |

All 60 source tests pass, including key uniqueness, required-field, accepted-value, and relationship checks. Both the initial and updated snapshots were generated twice and produced matching SHA-256 hashes. See [the Stage 3 report](./docs/stages/03-synthetic-sources.md) for commands and evidence.

Stage 4 adds five source-aligned staging views and two reusable intermediate views. Its build completed with all 124 selected tasks passing: 7 view models and 117 model and business-rule tests. See [the Stage 4 report](./docs/stages/04-staging-and-intermediate.md) for model grains, commands, and validation evidence.

Stage 5 adds the physical incremental Delta table `workspace.retail_marts.fact_order_line`. The controlled second run inserted 2,364 new keys and updated 836 existing rows through `MERGE`; the final 60,929-row fact reconciles exactly to its source with no duplicate keys. All 210 project tests pass. See [the Stage 5 report](./docs/stages/05-incremental-fact.md) for the reproducible proof.

The repository and live raw layer now contain the updated snapshot: 2,000 customers, 500 products, 20,800 orders, 60,929 order lines, and 17,446 fulfilments. The four dimensions, fulfilment fact, and dashboard are not claimed complete yet.
