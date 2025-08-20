# Task (GHA-J-2): Docker Build Workflow

*   **Use Case:** Create a workflow that triggers on a push to any branch named `feature/*`. Use the provided `Dockerfile` (located in Drive: `/Junior/GHA-J-2/prerequisites/`) to build a Docker image. The image does *not* need to be pushed to a registry.
*   **Verification:** Does the workflow trigger on feature branches? Does the Docker build step succeed?
*   **Solution:** Place in: `/Junior/GHA-J-2/solution.yml`
*   **Prerequisites:** See files in : `/Junior/GHA-J-2/prerequisites/`

---

# *Solutions: GHA-J-2 > Simple Docker Build Workflow*

## Task Layout

```
Junior/GHA-J-2/
  ├── prerequisites/
  │   ├── Dockerfile
  │   └── content/
  │       └── index.html
  ├── solution.yml                 # deliverable workflow for GHA-J-2
  └── README.md
```

---

## Step-by-Step Execution

## 1. Prepared the workflow file
  - Wrote `solution.yml` inside `Junior/GHA-J-1/` to define the workflow logic.

```yaml
# GHA-J-2 - Docker Build on feature branches

name: GHA-J-2 — Build Docker Image from Dockerfile

on:                          # EVENTS block starts
  workflow_dispatch:
  push:
    branches:
      - "feature/*"          # trigger on any branch named feature/<name>
    paths:
      - "Junior/GHA-J-2/**"
      - ".github/workflows/gha-j-2.yml"
# EVENTS block ends

jobs:                         # JOBS block starts
  build-image:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./Junior/GHA-J-2/prerequisites
    steps:                    # STEPS block starts
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build image (no push)
        run: docker build -t gha-j-2:${{ github.sha }} . # this tags the image with the commit SHA so each build has a unique tag. It helps identify which commit produced which image.

      - name: Verify image exists
        run: docker images | grep gha-j-2 
    # STEPS block ends
# JOBS block ends
```
---

## The provided Dockerfile (for reference)

```dockerfile
# Simple Dockerfile for Task GHA-J-2
# Builds a basic Nginx image serving a static file.
FROM nginx:1.25-alpine

# Copy static content into the default Nginx directory
COPY content/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Default Nginx command runs automatically
```
---

## 2. Placed a copy in GitHub's workflow directory to execute it

```
.github/workflows/gha-j-2.yml
```

## 3. Committed and pushed to `feature/GHA-J-2`:

```bash
git add .github/workflows/gha-j-2.yml
git commit -m "Adding GHA-J-2 workflow for building Docker image"
git push origin feature/GHA-J-2
```
---

## 4. Checked on the **GitHub Actions tab**. The workflow run named below was triggered on **feature** branch:

```
GHA-J-2 — Build Docker Image from Dockerfile
```
---

## 5. The Docker build step succeed:
   The successful Docker build step had a green check.

---

## Verification Note

- This way, the workflow was run on `feature/*` and then built the image from `Junior/GHA-J-2/prerequisites`, where the `Dockerfile` and `content/` live. 
- It **did not push** the image to a registry. 
- The final step lists the image to prove it exists.

---