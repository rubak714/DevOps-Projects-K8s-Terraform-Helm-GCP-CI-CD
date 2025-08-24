# Helm

# Task (Helm-M-1): Create Custom Chart

*   **Use Case:** Create a new Helm chart for a simple web application (e.g., using the provided Python Flask `Dockerfile` in folder: `/Mid-Level/Helm-M-1/prerequisites/`). The chart should create a Deployment and a ClusterIP Service. Make the number of replicas and the image tag configurable via `values.yaml`.
*   **Verification:** Is the chart structure correct? Do `helm template .` and `helm lint .` work? Are replicas and image tag configurable?
*   **Solution:** Place in: `/Mid-Level/Helm-M-1/solution_chart/`
*   **Prerequisites:** See files in: `/Mid-Level/Helm-M-1/prerequisites/`

---

# *Solutions: Helm-M-1 > Custom Helm Chart for Flask App*

## Task Layout

```
Mid-Level/Helm-M-1/
  ├── README.md
  ├── prerequisites/
  │   ├── app.py                   # python Flask app 
  │   ├── Dockerfile               # builds Flask image; runs on port 5000
  │   └── requirements.txt         # python dependencies
  └── solution_chart/              # helm chart implementation
        ├── Chart.yaml             # chart metadata
        ├── values.yaml            # configurable values> replicas, image repo, image tag, service
        └── templates/
             ├── _helpers.tpl      # helpers
             ├── deployment.yaml   # deployment for Flask app
             └── service.yaml      # ClusterIP Service
```

---

# Step-by-Step Execution

## 1. Provided Files 

**File:** `prerequisites/app.py`

<details>
<summary> Click here to expand app.py</summary>

```python
# Simple Flask app for Helm-M-1 prerequisite
import os
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello_world():
    """Returns a simple greeting."""
    # Example of potentially using an environment variable later
    api_key_status = "Not Set"
    if os.environ.get('API_KEY'):
        api_key_status = "Set (Hidden)" # Don't expose the key itself

    return jsonify(
        message="Hello from the Flask app deployed via Helm!",
        version="1.0",
        api_key_status=api_key_status
    )

@app.route('/health')
def health_check():
    """Basic health check endpoint."""
    return jsonify(status="UP"), 200

if __name__ == '__main__':
    # Note: Flask's development server is not recommended for production.
    # Use a production-grade WSGI server like Gunicorn or uWSGI.
    app.run(host='0.0.0.0', port=5000, debug=False) # Turn debug off for containers
```
</details>

---

<details>
<summary> Click here to expand Dockerfile</summary>


**File:** `prerequisites/Dockerfile`

```dockerfile
# Simple Python Flask app Dockerfile for Helm-M-1 prerequisite
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app.py .

# Metadata
LABEL maintainer="DevOps Test Applicant"
LABEL description="Simple Flask App for Helm Test"

# Expose the port Flask runs on
EXPOSE 5000

# Command to run the application using Flask development server
# Use gunicorn or similar for production scenarios
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]

```
</details>

---

## 2. Created Helm Chart Files

**File:** `solution_chart/Chart.yaml`

```yaml
apiVersion: v2
name: flask-helm-m1
description: A Helm chart for deploying a simple Flask web app
type: application
version: 0.1.0
appVersion: "1.0.0"
```

**File:** `solution_chart/values.yaml`

```yaml
# Default values for flask-helm-m1
# This is a YAML-formatted file.

# This will set the replicaset count more information can be found here: https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/
replicaCount: 2

image:
  # This sets the container image repository
  # More info: https://kubernetes.io/docs/concepts/containers/images/
  repository: gcr.io/PROJECT_ID_PLACEHOLDER/flask-helm-m1
  # This sets the image tag whose default is the chart appVersion.
  tag: "1.0.0"
  # This sets the pull policy for images.
  pullPolicy: IfNotPresent

# This is for setting up a service more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/
service:
  # This sets the service type more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  type: ClusterIP
  # This sets the ports more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/#field-spec-ports
  port: 5000

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
  create: false
  annotations: {}
  name: ""
```

**File:** `templates/_helpers.tpl`

```tpl
{{/* Expand the name of the chart. */}}
{{- define "flask-helm-m1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate a fully qualified name for resources. */}}
{{- define "flask-helm-m1.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "flask-helm-m1.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Compose chart name and version for labels like helm.sh/chart */}}
{{- define "flask-helm-m1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels applied to all resources */}}
{{- define "flask-helm-m1.labels" -}}
helm.sh/chart: {{ include "flask-helm-m1.chart" . }}
{{ include "flask-helm-m1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels shared by Deployment selector, pod template and Service selector */}}
{{- define "flask-helm-m1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-helm-m1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name helper */}}
{{- define "flask-helm-m1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "flask-helm-m1.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
```

**File:** `templates/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "flask-helm-m1.fullname" . }}
  labels:
    {{- include "flask-helm-m1.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "flask-helm-m1.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "flask-helm-m1.selectorLabels" . | nindent 8 }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
    spec:
      serviceAccountName: {{ include "flask-helm-m1.serviceAccountName" . }}
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.podSecurityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: flask
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 5000
          env:
            {{- if .Values.env }}
            {{- toYaml .Values.env | nindent 12 }}
            {{- end }}
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
      nodeSelector:
        {{- toYaml .Values.nodeSelector | nindent 8 }}
      tolerations:
        {{- toYaml .Values.tolerations | nindent 8 }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}

```

**File:** `templates/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "flask-helm-m1.fullname" . }}
  labels:
    {{- include "flask-helm-m1.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    {{- include "flask-helm-m1.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      port: {{ .Values.service.port }}
      targetPort: 5000
```

---

## 2. Local Build - Built the Docker image on minikube

```bash
# a local Kubernetes cluster with minikube
minikube start
kubectl config current-context       # should show minikube

# minikubes internal Docker daemon
eval $(minikube docker-env)

# the image was built directly into minikube’s Docker daemon
# the cluster can pull it without a registry
cd Mid-Level/Helm-M-1/prerequisites
docker build -t flask-helm-m1:1.0.0 .
```

## 3. Lint and template the Helm chart

```bash
cd ../solution_chart
# helm lint> validate chart structure and templates
helm lint .
# helm template> render manifests locally and confirm values are wired
helm template flask-helm-m1 .
```

Both commands completed without errors and render a Deployment and Service.

## 4. Upgraded the release

```bash
# installeD/ upgraded the release using local image
# the three --set flags can override values.yaml values, like currently using gcr.io
# fullnameOverride=flask-app was applied to avoid 'flask-helm-m1-flask-helm-m1' name 
helm upgrade --install flask-helm-m1 . \
  --set fullnameOverride=flask-app \
  --set image.repository=flask-helm-m1 \
  --set image.tag=1.0.0 \
  --set image.pullPolicy=IfNotPresent

# to observe overrided rendered YAML
helm template flask-helm-m1 . \
  --set fullnameOverride=flask-app

# checked pods and service
kubectl get pods,svc

```

## 5. uninstalled the release

```bash
helm uninstall flask-helm-m1

# stopped using minikube’s Docker 
eval $(minikube docker-env -u)

# sttopped the cluster
minikube stop

```

## 6. Outputs > Rendered YAML with override

```bash
# Source: flask-helm-m1/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app
  labels:
    helm.sh/chart: flask-helm-m1-0.1.0
    app.kubernetes.io/name: flask-helm-m1
    app.kubernetes.io/instance: flask-helm-m1
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/managed-by: Helm
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: flask-helm-m1
    app.kubernetes.io/instance: flask-helm-m1
  ports:
    - name: http
      port: 5000
      targetPort: 5000
---

# Source: flask-helm-m1/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  labels:
    helm.sh/chart: flask-helm-m1-0.1.0
    app.kubernetes.io/name: flask-helm-m1
    app.kubernetes.io/instance: flask-helm-m1
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: flask-helm-m1
      app.kubernetes.io/instance: flask-helm-m1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: flask-helm-m1
        app.kubernetes.io/instance: flask-helm-m1
      annotations:
        {}
    spec:
      serviceAccountName: default
      containers:
        - name: flask
          image: "gcr.io/PROJECT_ID_PLACEHOLDER/flask-helm-m1:1.0.0"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5000
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 20
          env:
          resources:
            {}
          securityContext:
            {}
      nodeSelector:
        {}
      tolerations:
        []
      affinity:
        {}
```
---

## Verification Notes

- `helm lint .` passed without errors.
- `helm template .` rendered the Deployment and Service manifests.
- Changing of `replicaCount` or `image.tag` using `values.yaml` file (via `--set` flags) changed the rendered output too.
- Service type was **ClusterIP** and exposed the app on port **5000**.
- Liveness and readiness probes pointed to `/health`.

---
