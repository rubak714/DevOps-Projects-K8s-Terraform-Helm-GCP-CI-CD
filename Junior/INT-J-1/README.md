# Task (INT-J-1): Terraform-Managed Configuration for Helm

*   **Use Case:** You want to centrally manage a configuration setting for a Helm application. Create Terraform code that creates a single object in a GCS bucket (e.g., a simple text file `config/settings.txt` with the content "Hello from Terraform!"). Then, create a simple Helm chart (provided in folder: `/Junior/INT-J-1/prerequisites/helm-chart/`) that expects this configuration value to be available as an environment variable `GREETING_MESSAGE` in the container (the value doesn't need to be dynamically read from GCS in the test; referencing it in the Deployment is sufficient). Finally, create a GitHub Actions workflow that:
    1.  Initializes and applies the Terraform code to ensure the GCS object exists.
    2.  Lints the Helm chart using `helm lint`.
    3.  Renders the Helm chart's manifests using `helm template`, setting the value for `GREETING_MESSAGE` (can be hardcoded in the workflow or `values.yaml`).
*   **Verification:** Does the workflow execute Terraform successfully? Is the Helm chart valid? Does the rendered Deployment manifest contain the `GREETING_MESSAGE` environment variable with a value?
*   **Solution:** Place in: `/Junior/INT-J-1/solution_terraform/`, `/Junior/INT-J-1/solution_helm/`, `/Junior/INT-J-1/solution_workflow.yml`
*   **Prerequisites:** See files in: `/Junior/INT-J-1/prerequisites/helm-chart/`

---

# Solutions: INT-J-1 > Terraform + Helm + GitHub Actions 

## Task Layout

```
Junior/INT-J-1/                  # Task folder for INT-J-1 (on feature branch)
    ├── README.md
    ├── solution_terraform/      # Terraform solution folder
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── versions.tf
    │   └── output.tf
    ├── solution_helm/           # Helm solution folder
    │   └── helm-chart/
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │           ├── _helpers.tpl
    │           └── deployment.yaml
    └── solution_workflow.yml    # GitHub Actions workflow solution
```

---

# Step-by-Step Execution 

## 1. Terraform - created GCS object with the greeting text

**File:** `versions.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

**File:** `main.tf`

```hcl
# configuring the Google Cloud provider only for Terraform
# project_id and region come from variables.tf

provider "google" {
  project = var.project_id
  region  = var.region
}

# generating a short random hex string
# this is used to make the bucket name globally unique

resource "random_id" "suffix" {
  byte_length = 4
}

# creating a Google Cloud Storage bucket
# "config" is terraform resource label 
# the GCS bucket> hold a small text object

resource "google_storage_bucket" "config" {
  name                        = "db-ms-intj1-${random_id.suffix.hex}"
  location                    = var.bucket_location
  uniform_bucket_level_access = true # enforcing IAM-only access
  force_destroy               = true
}

# creating a single text object inside the bucket with the greeting message
# "settings" is terraform resource label

resource "google_storage_bucket_object" "settings" {
  name    = "config/settings.txt"  # object key inside the bucket
  bucket  = google_storage_bucket.config.name  # attaching the object to the bucket created
  content = var.greeting_message   # content of the object comes from the variable greeting_message
}
```

**File:** `variables.tf`

```hcl
variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region (for provider)"
  default     = "europe-west3" # Frankfurt
}

variable "bucket_location" {
  type        = string
  description = "GCS location - multi-region like EU"
  default     = "EU"
}

variable "greeting_message" {
  type        = string
  description = "Text content to store in config/settings.txt"
  default     = "Hello from Terraform!"
}
```

**File:** `outputs.tf`

```hcl
output "bucket_name" {
  value = google_storage_bucket.config.name
}

output "settings_url" {
  value = "gs://${google_storage_bucket.config.name}/${google_storage_bucket_object.settings.name}"
}
```
---

## 2. After Writing Terraform Files - some commands were run locally in VS Code

```bash
gcloud auth login # logging into Google cloud with my user account in browser
gcloud auth application-default login # fixing 'application default credentials' so Terraform and SDKs can use my auth automatically
gcloud config set project stable-healer-418019 # ensuring inside the correct GCP project
gcloud services enable storage.googleapis.com # enabling the cloud storage API, as Terraform will create a GCS bucket and object
cd ./Junior/INT-J-1/solution_terraform # switching into my Terraform solution folder 

terraform init # initializing Terraform (which downloads google provider plugins and sets up the .terraform directory)
terraform validate # validating that my Terra. code syntax and configuration are valid

# applying the Terraform plan automatically with the needed variables
terraform apply -auto-approve \
  -var project_id=stable-healer-418019 \
  -var bucket_location=EU \
  -var greeting_message="Hello from Terraform!"

terraform output -raw bucket_name # the dynamically generated bucket name from Terra. outputs
terraform output -raw settings_url # the signed URL (gs:// path) of the uploaded 'settings.txt' text object file

# lastly, fetching and displaying the contents of the text object from GCS
# the output proves that the bucket + text object were created successfully and contains the greeting text
gcloud storage cat "$(terraform output -raw settings_url)"
```
---

## 3. Local Terraform Results

<p align="center">
  <img src="C:/Users/rubai/OneDrive/Desktop/git-DB/db_ms_junior_solutions/Junior/INT-J-1/solution_terraform/results1.png" alt="Terraform Result 1" width="600" />
</p>

<p align="center">
  <img src="C:/Users/rubai/OneDrive/Desktop/git-DB/db_ms_junior_solutions/Junior/INT-J-1/solution_terraform/results2.png" alt="Terraform Result 2" width="600" />
</p>
---

## 4. Helm chart - injected GREETING\_MESSAGE env var

**File:** `Chart.yaml`

```yaml
apiVersion: v2
name: simple-config-app
description: A basic Helm chart expecting a greeting that sets GREETING_MESSAGE as a container env var (Prerequisite for INT-J-1).
type: application
version: 0.1.0
appVersion: "1.0.0" 
```

**File:** `values.yaml`

```yaml
# Default values for simple-config-app (Prerequisite for INT-J-1).
replicaCount: 1

image:
  repository: nginx # Using Nginx as a placeholder container
  pullPolicy: IfNotPresent
  tag: "1.25-alpine"

# The greeting message is expected, provide a default or override via --set
# old greeting: "Default Greeting from values.yaml" # the old one/ given

# the greeting message is expected by the Helm chart as an environment variable
# previously, it was hardcoded in values.yaml ("Default Greeting from values.yaml")
# but here, passing it via an environment variable (GREETING_MESSAGE) because:
#   *. the same value can be set once in the GitHub Actions workflow and flow into both Terraform and Helm
#   *. it can be overriden easily at deploy time without editing the chart files
env:
  GREETING_MESSAGE: "Ola..Hello..from values.yaml"  # will be overridden by the workflow later

# Standard values below (can be simplified if needed)
imagePullSecrets: []
podAnnotations: {}
podLabels: {}
podSecurityContext: {}
securityContext: {}
resources: {}
nodeSelector: {}
tolerations: []
affinity: {}
serviceAccount:
  create: true
  annotations: {}
  name: ""

service:
  type: ClusterIP
  port: 80
```

**File:** `templates/_helpers.tpl`

```markdown
<details>
<summary> Click here to expand _helpers.tpl</summary>

```yaml
{{/* vim: set filetype=mustache: */}}
{{/* Expand the name of the chart. */}}
{{- define "simple-config-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create a default fully qualified app name. */}}
{{- define "simple-config-app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "simple-config-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels */}}
{{- define "simple-config-app.labels" -}}
helm.sh/chart: {{ include "simple-config-app.chart" . }}
{{ include "simple-config-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels */}}
{{- define "simple-config-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "simple-config-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Create the name of the service account to use */}}
{{- define "simple-config-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "simple-config-app.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
```
</details>
```

**File:** `templates/deployment.yaml`

```markdown
<details>
<summary> Click here to expand Deployment.yaml</summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "simple-config-app.fullname" . }}
  labels:
    {{- include "simple-config-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "simple-config-app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "simple-config-app.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "simple-config-app.serviceAccountName" . }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ .Chart.Name }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          env:
            - name: GREETING_MESSAGE
              # This value is expected to be provided by the deployment process (e.g., GitHub Actions)
              # It uses the value from values.yaml as a default or if overridden.
              value: {{ .Values.env.GREETING_MESSAGE | quote }}

          ports:
            - name: http
              containerPort: 80 # Nginx default port
              protocol: TCP
          # Basic probes for Nginx
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
```
</details>
```
---

## 5. Running Helm Commands Locally after Setting up the Chart

```bash
helm lint .            # validating the chart structure
# rendering the chart locally by overriding 
helm template demo . --set env.GREETING_MESSAGE="Hello from Terraform!" > rendered.yaml
# verifying in the rendered manifest that the environment variable is present
grep -n "name: GREETING_MESSAGE" rendered.yaml
grep -n 'value: "Hello from Terraform!"' rendered.yaml
```

---

## 6. Local Test Results

```bash
rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/INT-J-1/solution_helm/helm-chart   
$ grep -n "name: GREETING_MESSAGE" rendered.yaml
35:            - name: GREETING_MESSAGE

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/INT-J-1/solution_helm/helm-chart   
$ grep -n 'value: "Hello from Terraform!"' rendered.yaml
38:              value: "Hello from Terraform!"
```

---

## 7. GitHub Actions workflow — with Terraform apply, Helm lint, Helm template

  -Terraform uses a random_id bucket name and writes config/settings.txt with var.greeting_message.

  -Helm chart reads the env value from .Values.env.GREETING_MESSAGE.

  -One CI env var drives both Terraform and Helm so they stay in sync.

## 7.1: Setting up WIF in GCP:

To find project number:

```bash
gcloud projects describe stable-healer-418019 --format="value(projectNumber)"
```

### Step 1. Enabling APIs

```bash
gcloud components update
gcloud services enable iamcredentials.googleapis.com iam.googleapis.com sts.googleapis.com

# Enables APIs:
# IAM Service Account Credentials API
# Identity and Access Management (IAM) API
# Security Token Service API
```

### Step 2. Creating Service Account

```bash
gcloud iam service-accounts create int-j-1 \
    --description="For GitHub Actions via WIF" \
    --display-name="GitHub WIF Service Account"
```

### Step 3: Giving Permissions to the Service Account

```bash
gcloud projects add-iam-policy-binding stable-healer-418019 \
    --member="serviceAccount:int-j-1@stable-healer-418019.iam.gserviceaccount.com" \
    --role="roles/editor"
```

### Step 4: Creating an Identity Pool

```bash
gcloud iam workload-identity-pools create github-pool \
    --project=stable-healer-418019 \
    --location="global" \
    --display-name="GitHub Pool"
```

### Step 5: Creating a Provider for GitHub

```bash
gcloud iam workload-identity-pools providers create-oidc github-provider \
    --project=stable-healer-418019 \
    --location="global" \
    --workload-identity-pool="github-pool" \
    --display-name="GitHub OIDC Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
    --issuer-uri="https://token.actions.githubusercontent.com"
```

### Step 6: Allowing Service Account to be Impersonated

```bash
gcloud iam service-accounts add-iam-policy-binding \
    int-j-1@stable-healer-418019.iam.gserviceaccount.com \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe stable-healer-418019 --format="value(projectNumber)"))/locations/global/workloadIdentityPools/github-pool/attribute.repository/rubak714/DB-Solutions"
```

or,
```bash
PROJECT_NUMBER=$(gcloud projects describe stable-healer-418019 --format="value(projectNumber)")
SA_EMAIL="int-j-1@stable-healer-418019.iam.gserviceaccount.com"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/rubak714/DB-Solutions"
```

## 7.2: Under my Github Repo:

### To set WIF secrets:

GitHub → repo → Settings → Secrets and variables → Actions → New repository secret.
Added below each secret by name and value.

1. GCP_WIF_PROVIDER = projects/1015457000631/locations/global/workloadIdentityPools/github-pool/providers/github-provider

2. GCP_SA_EMAIL = int-j-1@stable-healer-418019.iam.gserviceaccount.com

3. GCP_PROJECT_ID = stable-healer-418019


## 8. Final Workflow File 

**File:** `/Junior/INT-J-1/solution_workflow.yml`

To make it actually run in GitHub, copied the same YAML to `.github/workflows/int-j-1.yml`.

```yaml
name: INT-J-1 — Terraform + Helm.

on:
  workflow_dispatch:
  push:
    branches: [ "main" ] # trigger on > main
    paths:
      - "Junior/INT-J-1/**"
      - ".github/workflows/int-j-1.yml"

permissions:
  id-token: write          # needed for WIF
  contents: read

env:
  # single source of truth for greeting used by both Terraform and Helm
  GREETING_MESSAGE: "Hello from Terraform!"
  TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}

 # directories
  TF_DIR: ./Junior/INT-J-1/solution_terraform
  HELM_DIR: ./Junior/INT-J-1/solution_helm/helm-chart
  RENDERED: ./Junior/INT-J-1/solution_helm/helm-chart/rendered.yaml

  # TF_VAR_region: "europe-west3"        # will uncomment, if override the default
  # TF_VAR_bucket_location: "EU"         # will uncomment, if override the default

jobs:
  terraform-helm-ci:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      # or, 
      # Workload Identity Federation auth
      # other option of hardcoding values here:
      #   workload_identity_provider: projects/1015457000631/locations/global/workloadIdentityPools/github-pool/providers/github-provider
      #   service_account: int-j-1@stable-healer-418019.iam.gserviceaccount.com

      # Authenticating to GCP (Workload Identity Federation)
      - name: Auth to GCP (WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
          service_account: ${{ secrets.GCP_SA_EMAIL }}
          create_credentials_file: true   # important 

      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v2

      # Terraform init and apply
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      # Making TF_VAR_greeting_message available to all following steps
      - name: Export TF_VAR_greeting_message
        run: echo "TF_VAR_greeting_message=${GREETING_MESSAGE}" >> "$GITHUB_ENV"

      - name: Terraform init
        working-directory: ${{ env.TF_DIR }}
        run: |
          terraform -version
          terraform init -input=false -lockfile=readonly

      - name: Terraform Validate and Plan (produces tfplan)
        working-directory: ${{ env.TF_DIR }}
        run: |
          terraform validate
          terraform plan -input=false -no-color -out=tfplan

      - name: Terraform Apply ( uses tfplan and creates bucket + config/settings.txt)
        if: github.ref == 'refs/heads/main'
        working-directory: ${{ env.TF_DIR }}
        run: terraform apply -auto-approve -input=false -no-color tfplan

      # Helm lint and template
      - name: Setup Helm
        uses: azure/setup-helm@v4

      - name: Helm lint
        working-directory: ${{ env.HELM_DIR }}
        run: helm lint .

      - name: Helm template with GREETING_MESSAGE
        working-directory: ${{ env.HELM_DIR }}
        run: |
          helm template demo . \
          --set env.GREETING_MESSAGE="${{ env.GREETING_MESSAGE }}" \
          > rendered.yaml

      - name: Verify GREETING_MESSAGE in rendered manifest
        working-directory: ${{ env.HELM_DIR }}
        run: |
          grep -q 'name: GREETING_MESSAGE' rendered.yaml
          grep -q "value: \"${{ env.GREETING_MESSAGE }}\"" rendered.yaml

      - name: Upload rendered manifest
        uses: actions/upload-artifact@v4
        with:
          name: rendered-manifests
          path: ${{ env.RENDERED }}
          if-no-files-found: error
```
---

## 9. GCP Output

<p align="center">
  <img src="C:/Users/rubai/OneDrive/Desktop/git-DB/db_ms_junior_solutions/bucket_creation.png" alt="GCP Output" width="600" />
</p>

## 9. Final Bash Commands

```bash
cd ~/OneDrive/Desktop/DB/solutions/Junior/

# which branch
git branch

git fetch origin
git checkout -b main origin/main

# switching to feature branch
# feature/INT-J-1
git checkout -b feature/GHA-J-2
git checkout feature/GHA-J-2
git push -u origin feature/GHA-J-2
git checkout feature/INT-J-1 -- GHA-J-2

git checkout main
# staged all changes
git add .github/
# committed changes
git commit -m "commits"
# pushed to GitHub
git push -u origin main
```

---

## Verification Notes

- Yes, the **Terraform was executed successfully**: `terraform init` and `terraform apply` run inside the workflow using my project idand bucket settings.
- **Helm chart was valid**: `helm lint` passes on `solution_helm`.
- **Rendered manifest contained the env var**: The `helm template` step wrote `rendered.yaml` and the `grep` step checked for `GREETING_MESSAGE` with the expected value.

---
