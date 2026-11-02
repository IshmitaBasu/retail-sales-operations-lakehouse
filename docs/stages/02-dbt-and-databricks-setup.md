# Stage 2 — Local dbt and Databricks setup

**Status:** Complete — connection and schemas validated November 2, 2026

## Purpose

Create a reproducible local dbt environment and connect it to the Databricks Free Edition Serverless Starter Warehouse without versioning workspace identifiers or credentials.

## Confirmed prerequisites

- Databricks Free Edition workspace is available.
- The included Serverless Starter Warehouse exists and is running.
- Its Connection Details page exposes the required server hostname and HTTP path.
- Power BI Desktop is installed.
- Python 3.11 is available locally.

## Version and connection decisions

- Python: 3.11
- dbt Core: 1.12.5
- `dbt-databricks`: 1.12.6
- Authentication: interactive user OAuth
- SQL compute: Free Edition Serverless Starter Warehouse
- Target catalog: `workspace`, subject to connection validation
- Base target schema: `retail`
- Threads: 2, to keep the free-tier workload small

With dbt's default schema naming, the project will build:

- `workspace.retail_raw`
- `workspace.retail_staging`
- `workspace.retail_intermediate`
- `workspace.retail_marts`

## Local installation

From the repository root:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
dbt --version
```

## Profile configuration

Copy the profile shown in `docs/profiles.yml.example` to the ignored project-local `.dbt/profiles.yml`, replacing the hostname and HTTP path with values from the SQL warehouse Connection Details page. Point dbt to it with `--profiles-dir .dbt` or the `DBT_PROFILES_DIR` environment variable.

The actual profile remains outside Git because the entire `.dbt/` directory is ignored. OAuth is selected so no Databricks token is stored in the project. This also avoids changing the existing BigQuery profile in the user's home directory.

## Validation commands

```powershell
$env:DBT_PROFILES_DIR = "$PWD\.dbt"
dbt debug
dbt parse --no-partial-parse
dbt show --inline "select current_catalog() as catalog_name, current_schema() as schema_name, current_timestamp() as checked_at"
```

The first OAuth connection may open a browser window for Databricks authorization.

## Completion checklist

- [x] Confirm Free Edition and the starter SQL warehouse.
- [x] Pin compatible Python packages.
- [x] Add a credential-free profile template.
- [x] Create the virtual environment and install dependencies.
- [x] Create an ignored local profile without changing the existing BigQuery profile.
- [x] Pass `dbt debug`.
- [x] Pass a non-partial parse.
- [x] Execute the connection query and confirm the catalog and schema.
- [x] Confirm no workspace identifiers or credentials are available to Git.

## Work log

- Created an isolated Python 3.11 virtual environment under the ignored `.venv/` directory.
- Pinned dbt Core 1.12.5 with `dbt-databricks` 1.12.6; the adapter requires dbt Core lower than 1.12.6.
- Installed and checked the dependency environment with no broken requirements.
- Kept the actual Databricks hostname and warehouse HTTP path only in ignored `.dbt/profiles.yml`.
- Used interactive OAuth; no Databricks personal access token was created or stored.
- Passed `dbt debug` against the Free Edition Serverless Starter Warehouse.
- Passed a non-partial project parse. The empty-resource configuration warnings are expected until Stage 3 adds seeds and models.
- Confirmed the live session resolves to catalog `workspace` and base schema `retail`.
- Added and ran the idempotent `create_project_schemas` macro.
- Verified `workspace.retail_raw`, `workspace.retail_staging`, `workspace.retail_intermediate`, and `workspace.retail_marts` through `information_schema`.

## Windows installation note

On this machine, the dbt experimental-parser build hook could not validate the local certificate chain when fetching its Windows wheel from GitHub. Installing the exact `dbt_core_experimental_parser` wheel from the official dbt Labs release resolved the machine-specific certificate issue without loosening project versions.
