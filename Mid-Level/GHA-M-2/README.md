# Task (GHA-M-2): Terraform Plan/Apply Workflow with Terraform Cloud

* **Use Case:** Set up a GitHub Actions workflow that uses Terraform Cloud for state management. On a pull request targeting `main`, it should run `terraform plan`. On a merge to `main`, it should run `terraform apply` (with auto-approval for this test). Use a Terraform Cloud API token stored in GitHub Secrets. Provide the Terraform backend configuration (`backend.tf`).
* **Verification:** Is the plan generated on PRs? Is apply executed on merges? Is the state stored in Terraform Cloud?
* **Solution:** Place in: `/Mid-Level/GHA-M-2/solution_workflow.yml`, `/Mid-Level/GHA-M-2/solution_backend.tf`

---

# *Solutions: GHA-M-2 > Terraform Cloud Plan/Apply*

## Task Layout

```
Mid-Level/GHA-M-2/
  ├── solution_workflow.yml   # GitHub Actions workflow (authoritative copy)
  ├── solution_backend.tf     # Terraform Cloud backend config
  ├── main.tf                 # Minimal TF config so plan/apply shows real output
  └── README.md
.github/workflows/
  └── gha-m-2.yml             # for testing > copy of solution_workflow.yml for CI/CD
```

---

## 1. Created a new branch for development

To test the pull request flow:

```bash
git checkout -b feature/gha-m-2
```
Work was done on this branch, then a PR was created against `main`. This triggers the **terraform plan** step.

---

## 2. Prepared the Terraform backend configuration

* Wrote `solution_backend.tf` to point state to Terraform Cloud. Used `db-solutions-org` and `gha-m-2-workspace` > my real Terraform Cloud org/workspace.

```hcl
# /Mid-Level/GHA-M-2/solution_backend.tf

terraform {
  backend "remote" {
    organization = "db-solutions-org"   

    workspaces {
      name = "gha-m-2-workspace"    
    }
  }
}
```
---

## 3. Prepared the GitHub Actions workflow

Wrote `solution_workflow.yml` to run plan on PR and apply on merge to `main`. It uses the Terraform Cloud token from `TF_API_TOKEN` secret.

```yaml
# /Mid-Level/GHA-M-2/solution_workflow.yml
# GHA-M-2: Terraform Plan/Apply Workflow with Terraform Cloud 
# Verification:
# - On a pull request/PR to main > `terraform plan` 
# - On merge to main > executes `terraform apply -auto-approve`
# - State > is managed in Terraform Cloud backend

name: GHA-M-2 --- Terraform Plan + Apply with Terraform Cloud 

on:
  workflow_dispatch:
  pull_request:
    branches: [ "main" ]
    paths:
      - "Mid-Level/GHA-M-2/**"
      - ".github/workflows/gha-m-2.yml"
  push:
    branches: [ "main" ]
    paths:
      - "Mid-Level/GHA-M-2/**"
      - ".github/workflows/gha-m-2.yml"

permissions:
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    env:
      TF_IN_AUTOMATION: "true"
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.8.5
          # injects TF Cloud token for app.terraform.io automatically
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Terraform Init (remote backend)
        working-directory: Mid-Level/GHA-M-2
        run: terraform init -input=false

      - name: Terraform Validate
        working-directory: Mid-Level/GHA-M-2
        run: terraform validate

      - name: Terraform Plan (PRs into main)
        if: github.event_name == 'pull_request'
        working-directory: Mid-Level/GHA-M-2
        run: terraform plan -no-color -input=false

      - name: Terraform Apply (after merge to main)
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        working-directory: Mid-Level/GHA-M-2
        run: terraform apply -auto-approve -input=false

```
---

## 4. Placed a copy in GitHub's workflow directory

```
.github/workflows/gha-m-2.yml
```

This was required because GitHub Actions only executes files inside `.github/workflows/`.

---

## 5. Committed and pushed the files

```bash
git add Mid-Level/GHA-M-2/solution_backend.tf Mid-Level/GHA-M-2/solution_workflow.yml .github/workflows/gha-m-2.yml
git commit -m "Add GHA-M-2 Terraform Cloud plan/apply"
git push origin feature/GHA-M-2
```

Then, opened a PR to `main` manually.

---

## 6. Verified

* The **PR** to `main` shows a Terraform **plan** output in the Actions logs.
* A **merge to main** runs **terraform apply** with `-auto-approve`.
* The **state** is stored in Terraform Cloud under the configured organization/workspace.

---

## Notes

* Secret required: `TF_API_TOKEN` in GitHub → Settings → Secrets and variables → Actions.
* Ensured the Terraform Cloud **workspace exists** and matches the backend `organization` and `workspaces.name` values.
