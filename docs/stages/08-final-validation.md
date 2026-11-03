# Stage 8 — Final validation and portfolio polish

**Status:** Repository validation complete — 3 November 2026; Power BI corrections remain tracked in Stage 7

## Purpose

Reconstruct the deterministic data workflow, repeat the incremental proof, run the complete dbt project, regenerate documentation, and verify that the public repository is reproducible and credential-safe.

## Reconstruction evidence

The documented initial-to-updated workflow was repeated against Databricks Free Edition.

| Check | Result |
|---|---:|
| Initial customers | 2,000 |
| Initial products | 500 |
| Initial orders | 20,000 |
| Initial order lines | 58,565 |
| Initial fulfilments | 16,776 |
| Updated orders | 20,800 |
| Updated order lines | 60,929 |
| Updated fulfilments | 17,446 |
| Expected incremental inserts | 2,364 |
| Expected changed existing rows | 836 |

The pre-merge audit returned:

```text
source_rows=60929
fact_rows=58565
missing_in_fact=2364
unexpected_in_fact=0
changed_existing_rows=836
duplicate_key_groups=0
```

After the normal incremental `MERGE`, the audit returned:

```text
source_rows=60929
fact_rows=60929
missing_in_fact=0
unexpected_in_fact=0
changed_existing_rows=0
duplicate_key_groups=0
```

The updated snapshot was regenerated again and every generated CSV and manifest SHA-256 hash remained unchanged.

## Final dbt validation

The complete final command was:

```powershell
dbt build --profiles-dir .dbt
```

Result:

```text
PASS=310 WARN=0 ERROR=0 SKIP=0 TOTAL=310
```

The run contained 5 seeds, 7 staging/intermediate views, 5 table models, 1 incremental model, 290 data tests, and 2 unit tests. `dbt docs generate --profiles-dir .dbt` then rebuilt `target/catalog.json` successfully. Adapter warnings about optional catalog comment metadata did not prevent catalog creation.

## Repository audit

| Audit | Result |
|---|---|
| Local Markdown links | Pass — no missing targets |
| Tracked credential-pattern scan | Pass |
| Tracked generated/configuration artifact scan | Pass |
| `.dbt/profiles.yml` | Ignored |
| Local `.pbix` | Ignored |
| Power BI previews | Four PNG files versioned with no connection details visible |
| Git whitespace check | Pass |

The scan covered Databricks host and HTTP-path patterns, personal access token patterns, email addresses, private-key headers, local profiles, `.databrickscfg`, `.pbix`, `.pbids`, `.token`, `target`, `logs`, `.venv`, and `.dbt` artifacts.

## Portfolio documentation

The root README now contains:

- Architecture and technology summary
- Four Power BI page previews
- Certified mart grains and row counts
- Reproduction commands
- Validation evidence
- Security boundary
- Limitations and cleanup guidance
- Accurate CV wording

Stage 8 repository work is complete. The overall project remains honestly marked in progress until the Stage 7 Power BI correction checklist is applied and the corrected report values are reconciled.
