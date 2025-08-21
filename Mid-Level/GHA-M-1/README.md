# GitHub Actions

# Task (GHA-M-1): CI/CD with Docker Push & Helm Deploy Trigger

*   **Use Case:** Create a workflow triggered on merge to the `main` branch. The workflow should:
    1.  Build a Docker image using a provided `Dockerfile` (See folder: `/Mid-Level/GHA-M-1/prerequisites/`).
    2.  Tag the image with the Git commit SHA and push it to Google Artifact Registry (GAR). Authenticate using Workload Identity Federation (preferred) or a Service Account key stored in GitHub Secrets.
    3.  Simulate triggering a Helm deployment with the new image tag (e.g., by printing the `helm upgrade` command that would be used).
*   **Verification:** Does the build & push to GAR work? Is authentication handled correctly? Is the simulated Helm deploy step triggered with the correct image tag?
*   **Solution:** Place in: `/Mid-Level/GHA-M-1/solution.yml`
*   **Prerequisites:** See files in: `/Mid-Level/GHA-M-1/prerequisites/`

---

# *Solutions: GHA-M-1 > CI/CD Docker + Helm Simulation*

## Task Layout

```
Mid-Level/GHA-M-1/
  ├── prerequisites/
  │    ├── Dockerfile          # provided Dockerfile (nginx serving index.html)
  │    └── content/index.html  # static test page
  ├── solution.yml             # deliverable workflow for GHA-M-1
  └── README.md
```

---

# Step-by-Step Execution

## 1. Prepared the workflow file

* Wrote `solution.yml` inside `Mid-Level/GHA-M-1/` to define the CI/CD pipeline.

```yaml
# /Mid-Level/GHA-M-1/solution.yml
# GHA-M-1: CI/CD with Docker Push & Helm Deploy Trigger (simulation only)

name: GHA-M-1 --- CI/CD with Docker Push + Helm Deploy Trigger

on:
  workflow_dispatch:
  push:
    branches: [ "main" ]
    paths:
      - "Mid-Level/GHA-M-1/**"
      - ".github/workflows/gha-m-1.yml"

permissions:
  contents: read
  id-token: write

jobs:
  build-push-simulate-helm:
    runs-on: ubuntu-latest
    env:
      PROJECT_ID: "stable-healer-418019"
      GAR_REGION: "europe-west3"
      GAR_REPO: "apps"
      IMAGE_NAME: "gha-m-1-app"
      DOCKERFILE_DIR: "Mid-Level/GHA-M-1/prerequisites"
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
          service_account: ${{ secrets.GCP_WIF_SERVICE_ACCOUNT }}

      - name: Set up gcloud
        uses: google-github-actions/setup-gcloud@v2

      - name: Ensure GAR repository exists 
        run: |
          if ! gcloud artifacts repositories describe "$GAR_REPO" --location="$GAR_REGION" >/dev/null 2>&1; then
            gcloud artifacts repositories create "$GAR_REPO" \
              --repository-format=docker \
              --location="$GAR_REGION" \
              --description="Docker images for mid-level tasks"
          else
            echo "Repository $GAR_REPO already exists in $GAR_REGION"
          fi

      - name: Configure Docker for GAR
        run: gcloud auth configure-docker $GAR_REGION-docker.pkg.dev --quiet

      - name: Build Docker image
        run: docker build -t "$GAR_REGION-docker.pkg.dev/$PROJECT_ID/$GAR_REPO/$IMAGE_NAME:sha-${GITHUB_SHA::8}" "$DOCKERFILE_DIR"

      - name: Push Docker image to GAR
        run: docker push "$GAR_REGION-docker.pkg.dev/$PROJECT_ID/$GAR_REPO/$IMAGE_NAME:sha-${GITHUB_SHA::8}"

      - name: Simulate Helm deploy (echo only)
        run: |
          echo "helm upgrade --install gha-m-1 bitnami/nginx \
            --set image.registry='$GAR_REGION-docker.pkg.dev' \
            --set image.repository='$PROJECT_ID/$GAR_REPO/$IMAGE_NAME' \
            --set image.tag='sha-${GITHUB_SHA::8}' \
            --namespace default"

      - name: Summary
        run: |
          echo "Built and pushed: $GAR_REGION-docker.pkg.dev/$PROJECT_ID/$GAR_REPO/$IMAGE_NAME:sha-${GITHUB_SHA::8}"
          echo "Simulated Helm command printed above (bitnami/nginx). No deployment performed."

```

---

## 2. Placed a copy in GitHub's workflow directory to execute it

```
.github/workflows/gha-m-1.yml
```

---

## 3. Committed and pushed to `main`:

```bash
git add Mid-Level/GHA-M-1/solution.yml .github/workflows/gha-m-1.yml
git commit -m "Add gha-m-1.yml GitHub Actions workflow for GHA-M-1 Task"
git push origin main
```

---

## 4. Checked on the **GitHub Actions tab**. The workflow run named below is seen:

```
GHA-M-1 --- CI/CD with Docker Push + Helm Deploy Trigger
```

---

## 5. Verified the output:

In the final **Simulate Helm deploy** step, the log shows a valid `helm upgrade` command, for example:

```
helm upgrade --install gha-m-1 bitnami/nginx \
  --set image.registry='europe-west3-docker.pkg.dev' \
  --set image.repository='stable-healer-418019/apps/gha-m-1-app' \
  --set image.tag='sha-a1b2c3d4' \
  --namespace default
```

This confirms the Docker image was built, pushed and the Helm command was generated correctly.

---

## Additional: Workload Identity Federation (WIF) setup for Mid-Level Tasks

This allows GitHub Actions jobs from my repo to impersonate mid-level service account via WIF.

## Prerequisites_1 > Enable APIs with gcloud

```bash
PROJECT_ID=stable-healer-418019
gcloud config set project ${PROJECT_ID}

# enable required APIs
gcloud services enable \
  serviceusage.googleapis.com \ 
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \    # already enabled in previous project, for reference
  iam.googleapis.com \               # already enabled in previous project
  sts.googleapis.com                 # already enabled in previous project
```

---

## Prerequisites_2 > Created Artifact Registry repository

```bash
PROJECT_ID=stable-healer-418019
REGION=europe-west3
REPO=apps

# creation of the Docker repo if it does not exist
if ! gcloud artifacts repositories describe ${REPO} --location=${REGION} >/dev/null 2>&1; then
  gcloud artifacts repositories create ${REPO} \
    --project=${PROJECT_ID} \
    --repository-format=docker \
    --location=${REGION} \
    --description="Docker images for mid-level tasks"
else
  echo "Repository ${REPO} already exists in ${REGION}"
fi

# allowing the CI service account to push images
PROJECT_ID=stable-healer-418019
SA=mid-level@${PROJECT_ID}.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${SA} \
  --role=roles/artifactregistry.writer

```

---

### Step 1. Created Service Account

```bash
gcloud iam service-accounts create mid-level \
    --description="For GitHub Actions via WIF" \
    --display-name="GitHub WIF Service Account"
```

### Step 2. Inputs

* Project ID: `stable-healer-418019`
* Project Number: `1015457000631`
* Pool ID: `github-pool`
* GitHub Repo: `rubak714/DB-Solutions`
* Service Account: `mid-level@stable-healer-418019.iam.gserviceaccount.com`

---

### Step 3. Allowing Mid-Level Service Account to be Impersonated

```bash
PROJECT_ID=stable-healer-418019
PROJECT_NUMBER=1015457000631
POOL_ID=github-pool
OWNER=rubak714
REPO=DB-Solutions
SA_EMAIL=mid-level@stable-healer-418019.iam.gserviceaccount.com

# binding the GitHub repo identity (subject mapping) to the service account
gcloud iam service-accounts add-iam-policy-binding \
  ${SA} \
  --role=roles/iam.workloadIdentityUser \
  --member="principal://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/subject/repo:${OWNER}/${REPO}"

```

---

### Step 3. Giving Permissions to the Service Account

```bash
# allowing pushing Docker images to Artifact Registry
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${SA_EMAIL} \
  --role=roles/artifactregistry.writer

# allowing managing Kubernetes resources
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${SA_EMAIL} \
  --role=roles/container.admin

# allowing reading from Secret Manager
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member=serviceAccount:${SA_EMAIL} \
  --role=roles/secretmanager.secretAccessor
```

---

### Step 4. GitHub Repository Secrets

By going to: GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret and added below each secret by name and value.:

* `GCP_WIF_PROVIDER` = `projects/1015457000631/locations/global/workloadIdentityPools/github-pool/providers/github-provider`
* `GCP_WIF_SERVICE_ACCOUNT` = `mid-level@stable-healer-418019.iam.gserviceaccount.com`

---

## Verification Note

- Steps initially performed: required APIs enabled and GAR repo creation.
- The **build and push to GAR** was completed successfully using the provided Dockerfile.
- **Authentication with Workload Identity Federation** worked as expected.
- The workflow printed the **simulated Helm command** with the correct image repo and SHA tag.
- The **Docker image (Nginx)** was built and pushed to GAR correctly.

---