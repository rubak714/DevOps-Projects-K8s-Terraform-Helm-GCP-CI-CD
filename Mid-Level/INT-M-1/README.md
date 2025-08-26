# Integrated Task

# Task (INT-M-1): GKE Deployment with External Secret & Istio Sidecar

*   **Use Case:** An application running on GKE needs an API key securely stored in Google Secret Manager. The application should also be part of the Istio service mesh.
*   **Steps:**
    1.  **Terraform:** Ensure your Terraform code creates a GKE cluster and a Secret in Google Secret Manager (`api-key-secret`).
    2.  **Helm:** Modify a Helm chart:
        *   The Deployment should expect an `API_KEY` environment variable sourced from a Kubernetes Secret named `app-secrets` (key: `api-key`).
        *   Add the annotation `sidecar.istio.io/inject: "true"` to the Pod template metadata to enable Istio sidecar injection.
    3.  **GitHub Actions:** Create a workflow that:
        *   Authenticates to Google Cloud.
        *   Runs `terraform apply` to ensure GKE cluster & GSM secret exist.
        *   Configures `kubectl` context for the GKE cluster.
        *   Retrieves the secret value from Google Secret Manager.
        *   Creates/updates a Kubernetes Secret (`app-secrets`) in the target namespace with the retrieved value.
        *   Deploys the Helm chart using `helm upgrade --install`.
*   **Verification:** Does the workflow complete successfully? Is the k8s Secret created correctly? Does the Helm Deployment contain the Secret reference and Istio annotation? Is the Helm chart successfully applied to GKE?
*   **Solution:** Place in: `/Mid-Level/INT-M-1/solution_terraform/` (combines TF-M-1 & TF-M-2 logic), `/Mid-Level/INT-M-1/solution_helm/`, `/Mid-Level/INT-M-1/solution_workflow.yml`

---

# *Solutions: INT-M-1 > GKE + Secret Manager + Istio + Helm + GitHub Actions*

## This task is on **chore/cleanup-terraform** branch and not **main**

I pushed the **INT-M-1** solution to **chore/cleanup-terraform** on purpose. The **main branch** had leftover .terraform artifacts from earlier tests that polluted Terraform state and caused repeated init/apply issues.

## Task Layout

```
Mid-Level/INT-M-1/
  ├── solution_terraform/
  │    ├── gke.tf           # GKE cluster setup > based on TF-M-1
  │    ├── secret.tf        # GSM secret creation > based on TF-M-2
  │    ├── variables.tf     # input variables
  │    ├── outputs.tf       # outputs cluster name, region, secret id
  │    └── terraform.tfvars # local values 
  │
  ├── solution_helm/
  │    ├── Chart.yaml       # chart metadata
  │    ├── values.yaml      # replicaCount, image, secret keys
  │    └── templates/
  │         ├── _helpers.tpl
  │         ├── deployment.yaml   # deployment with Istio annotation and secret ref
  │         └── service.yaml      # ClusterIP service
  │
  └── solution_workflow.yml # gitHub actions > CI/CD workflow
```

---

## 1. Created Terraform Files

**File:** `solution_terraform/gke.tf`

```hcl
# Provision a GKE cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 30.0"

  project_id = var.project_id
  name       = "int-m-1-gke-${random_string.suffix.result}"  # <— unique

  regional = false
  zones    = [var.zone]

  network    = google_compute_network.gke_network.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  ip_range_pods     = "pods-${random_string.suffix.result}"
  ip_range_services = "services-${random_string.suffix.result}"

  create_service_account = false
  service_account        = "int-m-1@stable-healer-418019.iam.gserviceaccount.com"

  node_pools = [
    {
      name         = "default-node-pool"
      machine_type = var.machine_type
      disk_size_gb = 30
      min_count    = 1
      max_count    = 3
    }
  ]
}
```
---

**File:** `solution_terraform/network.tf`

```hcl
resource "google_compute_network" "gke_network" {
  name                    = "gke-vpc-${random_string.suffix.result}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnet" {
  name          = "gke-subnet-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.gke_network.id

  secondary_ip_range = [
    {
      range_name    = "pods-${random_string.suffix.result}"
      ip_cidr_range = "10.4.0.0/14"
    },
    {
      range_name    = "services-${random_string.suffix.result}"
      ip_cidr_range = "10.8.0.0/20"
    }
  ]
}
```

---

**File:** `secret.tf`

```hcl
# created a secret in Google Secret Manager
resource "google_secret_manager_secret" "api_key_secret" {
  secret_id = "api-key-secret-${random_string.suffix.result}"
  replication { 
    auto {} 
    }
}
```
---

**File:** `variables.tf`

```hcl
variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}
```
---

**File:** `outputs.tf`

```hcl
output "cluster_name" {
  value = module.gke.name
}

output "secret_name" {
  value = google_secret_manager_secret.api_key_secret.secret_id
}
```

---

## 2. Created Helm Chart Files

**File:** `solution_helm/Chart.yaml`

```yaml
apiVersion: v2
name: flask-int-m1
description: A Helm chart for deploying the Flask INT-M-1 app with Istio sidecar and external secret reference
version: 0.1.0
appVersion: "1.0.0"
type: application
```

---

**File:** `solution_helm/values.yaml`

```yaml
replicaCount: 2

image:
  repository: gcr.io/PROJECT_ID_PLACEHOLDER/flask-int-m1
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 5000
```
---

**File:** `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "flask-int-m1.fullname" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "flask-int-m1.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        sidecar.istio.io/inject: "true"
      labels:
        {{- include "flask-int-m1.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: flask
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 5000
        env:
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
```

---

**File:** `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "flask-int-m1.fullname" . }}
  labels:
    {{- include "flask-int-m1.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: 5000
      protocol: TCP
      name: http
  selector:
    {{- include "flask-int-m1.selectorLabels" . | nindent 4 }}
```

---

**File:** `templates/_helpers.tpl`

```tpl
# File: solution_helm/templates/_helpers.tpl

{{/* Expand the name of the chart */}}
{{- define "flask-int-m1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate a fully qualified app name */}}
{{- define "flask-int-m1.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "flask-int-m1.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Chart name and version as used by the chart label */}}
{{- define "flask-int-m1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels applied to all resources */}}
{{- define "flask-int-m1.labels" -}}
helm.sh/chart: {{ include "flask-int-m1.chart" . }}
{{ include "flask-int-m1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels shared by Deployment selector, Pod template, and Service selector */}}
{{- define "flask-int-m1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-int-m1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name helper */}}
{{- define "flask-int-m1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "flask-int-m1.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
```

---

## 3. GitHub Actions 

**File:** `solution_helm/solution_workflow.yml`

```yaml
name: INT-M-1 --- GKE with Secret and Istio

on:
  push:
    branches: [ "chore/cleanup-terraform" ]
  workflow_dispatch: {}

permissions:
  id-token: write
  contents: read

env:
  TF_DIR: ./Mid-Level/INT-M-1/solution_terraform
  HELM_DIR: ./Mid-Level/INT-M-1/solution_helm
  GCP_PROJECT: ${{ secrets.GCP_PROJECT_ID }}   
  REGION: europe-west1
  ZONE: europe-west1-b
  CLUSTER: int-m-1-gke
  NAMESPACE: default
  RELEASE: int-m-1
  IMAGE_REPO: gcr.io/${{ secrets.GCP_PROJECT_ID }}/flask-int-m1
  IMAGE_TAG: 1.0.0
  GSM_SECRET_ID: api-key-secret
  K8S_SECRET_NAME: app-secrets
  K8S_SECRET_KEY: api-key

jobs:
  GKE_with_Secret_and_Istio:
    runs-on: ubuntu-latest
    steps:
      # pulling repo contents
      - uses: actions/checkout@v4

      # Authenticate to GCP via OIDC 
      - name: Auth to Google Cloud (WIF)
        uses: google-github-actions/auth@v2.1.6
        with:
          workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
          service_account: ${{ secrets.GCP_SA_EMAIL }}

      # Install gcloud SDK
      - name: Setup gcloud
      - uses: google-github-actions/setup-gcloud@v2.1.0

      # Install the GKE auth plugin and enable it
      - name: Install GKE auth plugin
        run: |
          gcloud components install gke-gcloud-auth-plugin -q
          echo "USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> "$GITHUB_ENV"

      # Install kubectl and helm
      - uses: azure/setup-kubectl@v4
      - uses: azure/setup-helm@v4

      # Install Terraform
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.13.0
          terraform_wrapper: false

      # Provision GKE with Terraform 
      - name: Terraform init and apply
        working-directory: ${{ env.TF_DIR }}
        run: |
          terraform init -upgrade
          terraform apply -auto-approve \
            -var "project_id=$GCP_PROJECT" \
            -var "region=$REGION" \
            -var "zone=$ZONE"

      # Export Terraform outputs to the job environment when present 
      - name: Export cluster name to env
        working-directory: ${{ env.TF_DIR }}
        run: |
          if terraform output -raw cluster_name >/dev/null 2>&1; then
            echo "CLUSTER=$(terraform output -raw cluster_name)" >> "$GITHUB_ENV"
          fi

      # if the Terraform code exposes a GSM secret output, can capture it
      - name: Export GSM secret name to env
        working-directory: ${{ env.TF_DIR }}
        run: |
          if terraform output -raw secret_name >/dev/null 2>&1; then
            echo "GSM_SECRET_ID=$(terraform output -raw secret_name)" >> "$GITHUB_ENV"
          fi

      # quick visibility to confirm that auth context and that Secret Manager is reachable.
      - name: Debug GSM access
        run: |
          set -x
          gcloud auth list
          gcloud config list
          gcloud secrets describe "$GSM_SECRET_ID" --project "$GCP_PROJECT" || true

      # Ensure the Secret Manager secret exists. This is idempotent>>> describe/create
      - name: Ensure secret exists (idempotent)
        run: |
          gcloud secrets describe "$GSM_SECRET_ID" --project "$GCP_PROJECT" >/dev/null 2>&1 || \
          gcloud secrets create "$GSM_SECRET_ID" --replication-policy="automatic" --project "$GCP_PROJECT"

      # Push the current API key from GitHub Secrets to GSM as > a new version.
      - name: Push latest API key to GSM
        run: |
          set -euo pipefail
          if [[ -z "${{ secrets.API_KEY_VALUE }}" ]]; then
            echo "ERROR: secrets.API_KEY_VALUE is empty." >&2; exit 1
          fi
          printf "%s" "${{ secrets.API_KEY_VALUE }}" | \
            gcloud secrets versions add "$GSM_SECRET_ID" --data-file=- --project "$GCP_PROJECT"

      # Point kubectl > at the new cluster and pin the namespace for the rest of the job
      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials "$CLUSTER" \
            --zone "$ZONE" --project "$GCP_PROJECT"
          kubectl config set-context --current --namespace="$NAMESPACE"

      # Create/update the Kubernetes Secret from the latest GSM version
      - name: Create/Update Kubernetes Secret
        run: |
          VALUE=$(gcloud secrets versions access latest \
            --secret="$GSM_SECRET_ID" --project "$GCP_PROJECT")
          kubectl create secret generic "$K8S_SECRET_NAME" \
            --from-literal "$K8S_SECRET_KEY=$VALUE" \
            --namespace "$NAMESPACE" \
            --dry-run=client -o yaml | kubectl apply -f -

      # Deploy/upgrade the app via Helm. I override only repo and tag here
      - name: Helm deploy
        run: |
          helm upgrade --install "$RELEASE" "$HELM_DIR" \
            --namespace "$NAMESPACE" \
            --set image.repository="$IMAGE_REPO" \
            --set image.tag="$IMAGE_TAG"

```

## 4. Placed a copy in GitHub's workflow directory to execute it

```
.github/workflows/int-m-1.yml
```

---

## 5. Committed and pushed to `main`:

```bash
git add .github/workflows/int-m-1.yml
git commit -m "Add int-m-1.yml GitHub Actions workflow for INT-M-1 Task"
git push origin main
```

---

## 6. Checked on the **GitHub Actions tab**. The workflow run named below is seen:

```
INT-M-1 --- GKE with Secret and Istio 
```
---

## Verification Notes

- `terraform apply` provisioned the GKE cluster and created a Secret in Google Secret Manager.
- GitHub Actions workflow retrieved the secret securely and created a Kubernetes Secret (`app-secrets`).
- Deployment referenced this Kubernetes Secret under `env.valueFrom.secretKeyRef`.
- Istio sidecar injection annotation (`sidecar.istio.io/inject: "true"`) was included in the Pod template metadata.
- Helm applied the chart into the GKE cluster successfully.

---

## References

- https://alexanderhose.com/how-to-integrate-github-actions-with-google-cloud-platform/#:~:text=permissions%3A%20id
- https://medium.com/@gravish316/setup-ci-cd-using-github-actions-to-deploy-to-google-kubernetes-engine-ef465a482fd
- https://medium.com/@onefabulousginger/using-github-actions-to-deploy-to-gke-with-helm-81855414db0b
- https://spacelift.io/blog/github-actions-kubernetes
- https://medium.com/@ebohgoodness.e/what-it-takes-to-securely-deploy-a-microservice-application-on-kubernetes-using-gcp-terraform-afe794348bea
- https://faun.pub/building-ci-cd-pipeline-with-github-action-63082aa0bd1d
- https://medium.com/@armyost1/creating-typical-ci-cd-pipeline-with-gke-and-github-actions-8225cce9e4d4
