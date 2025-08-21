# Task (GHA-J-1): Simple CI Workflow

*   **Use Case:** Create a GitHub Actions workflow that triggers automatically on every push to the `main` branch. The workflow should simply print a message (e.g., "Workflow triggered for main branch").
*   **Verification:** Is the trigger correct? Is the syntax valid? Is the message printed?
*   **Solution:** Place in: `/Junior/GHA-J-1/solution.yml`

---

# *Solutions: GHA-J-1 --- Simple CI Workflow*

## Task Layout

```
Junior/GHA-J-1/
  ├── solution.yml                 # deliverable workflow for GHA-J-1
  └── README.md
```

---

# Step-by-Step Execution

## 1. Prepared the workflow file
   - Wrote `solution.yml` inside `Junior/GHA-J-1/` to define the workflow logic.

```yaml
# /Junior/GHA-J-1/solution.yml
# GHA-J-1: Simple CI Workflow
# Verification:
# - Trigger: on push to 'main' only 
# - Syntax: valid YAML for GitHub Actions
# - Message: prints "Workflow triggered for main branch"

name: GHA-J-1 --- Simple CI

on:
  push:
    branches: [ "main" ]
    paths:
        - "Junior/GHA-J-1/**"
        - ".github/workflows/gha-j-1.yml" 

jobs:
  Ola-hello:
    runs-on: ubuntu-latest
    steps:
      # Standard practice to check out the repo
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Print message
        run: echo "Workflow triggered for main branch"
```
---

## 2. Placed a copy in GitHub's workflow directory to execute it

```
.github/workflows/gha-j-1.yml
```

---

## 3. Committed and pushed to `main`:

```bash
git add Junior/GHA-J-1/solution.yml .github/workflows/gha-j-1.yml
git commit -m "Adding GHA-J-1 simple CI workflow"
git push origin main
```
---

## 4. Checked on the **GitHub Actions tab**. The workflow run named below is seen:

```
GHA-J-1 --- Simple CI
```
---

## 5. Verified the output:
   In the **Print message** step, it is seen as:

```
Workflow triggered for main branch
```
---