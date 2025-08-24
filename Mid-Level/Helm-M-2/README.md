# Helm

# Task (Helm-M-2): Conditional Resource & Secret Placeholder

*   **Use Case:** Extend the chart from Helm-M-1. Add an Ingress resource that is only created if `ingress.enabled=true` is set in `values.yaml`. Also, add placeholder environment variables in the Deployment that should be sourced from a Secret named `{{ include "mychart.fullname" . }}-secrets` (e.g., `API_KEY`). The Secret itself should *not* be part of the chart (simulating external secret management).
*   **Verification:** Is the Ingress only rendered when `enabled=true`? Does the Deployment correctly reference the expected Secret name?
*   **Solution:** Place in: `/Mid-Level/Helm-M-2/solution_chart/` (showing relevant changes in `values.yaml`, `templates/ingress.yaml`, `templates/deployment.yaml`)

---

# *Solutions: Helm-M-2 > Conditional Ingress + Secret Placeholder*

## Task Layout

```
Mid-Level/Helm-M-2/
  ├── README.md
  └── solution_chart/
      ├── Chart.yaml          # same metadata style as Helm-M-1, appVersion bumped
      ├── values.yaml         # adds ingress section and env placeholders
      └── templates/
          ├── _helpers.tpl    # reuse helpers from Helm-M-1 and one addition
          ├── deployment.yaml # updated with secretKeyRef placeholders
          └── ingress.yaml    # rendered only when ingress.enabled=true
```

---

## 1. Values changed (`values.yaml`)

**File:** `templates/values.yaml`

```yaml
# Default values for flask-helm-m1 (Helm-M-2 additions)

replicaCount: 2

image:
  repository: gcr.io/PROJECT_ID_PLACEHOLDER/flask-helm-m1
  tag: "1.1.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 5000

# Ingress is off by default. 
ingress:
  enabled: false
  className: ""          # "nginx"/"gce"
  annotations: {}         # kubernetes.io/ingress.class: nginx
  hosts:
    - host: example.com
      paths:
        - path: /
          pathType: Prefix

# placeholder env that will be read from an external Secret named "<fullname>-secrets"
secretEnvKeys:
  - name: API_KEY
  - name: API_TOKEN

# Standard sections carried over
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

---

## 2. Deployment update

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
    spec:
      serviceAccountName: {{ include "flask-helm-m1.serviceAccountName" . }}
      containers:
        - name: flask
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: 5000
          # The following env entries reference an EXTERNAL Secret named "<fullname>-secrets".
          # Only keys listed in .Values.secretEnvKeys will be requested.
          env:
            {{- $secretName := include "flask-helm-m1.secretName" . -}}
            {{- range .Values.secretEnvKeys }}
            - name: {{ .name }}
              valueFrom:
                secretKeyRef:
                  name: {{ $secretName }}
                  key: {{ .name }}
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

---

## 3. Conditional Ingress 

**File:** `templates/ingress.yam`

```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "flask-helm-m1.fullname" . }}
  labels:
    {{- include "flask-helm-m1.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress.className }}
  ingressClassName: {{ .Values.ingress.className }}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "flask-helm-m1.fullname" $ }}
                port:
                  number: {{ $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end }}
```

---

## 4. Local Testing

## Rendered with Ingress disabled > default

  ```bash
  cd Mid-Level/Helm-M-2/solution_chart
  helm lint .
  # searches for Ingress definitions in the rendered output
  helm template helm-m2 . | grep -i "^kind: Ingress" -n || echo "no ingress rendered (expected)"
  ```

## Rendered with Ingress enabled and two secret keys

  ```bash
  helm template helm-m2 . \
    --set ingress.enabled=true \
    --set ingress.className=nginx \
    --set secretEnvKeys[0].name=API_KEY \
    --set secretEnvKeys[1].name=API_TOKEN \
    | sed -n '1,200p'
  ```

## 5. Outputs > Rendered YAML with Ingress enabled and two secret keys

```bash
---
# Source: flask-helm-m1/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helm-m2-flask-helm-m1
  labels:
    helm.sh/chart: flask-helm-m1-0.2.0
    app.kubernetes.io/name: flask-helm-m1
    app.kubernetes.io/instance: helm-m2
    app.kubernetes.io/version: "1.1.0"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: flask-helm-m1
      app.kubernetes.io/instance: helm-m2
  template:
    metadata:
      labels:
        app.kubernetes.io/name: flask-helm-m1
        app.kubernetes.io/instance: helm-m2
    spec:
      serviceAccountName: default
      containers:
        - name: flask
          image: "gcr.io/PROJECT_ID_PLACEHOLDER/flask-helm-m1:1.1.0"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5000
          # The following env entries reference an EXTERNAL Secret named "<fullname>-secrets".
          # Only keys listed in .Values.secretEnvKeys will be requested.
          env:
            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: helm-m2-flask-helm-m1-secrets
                  key: API_KEY
            - name: API_TOKEN
              valueFrom:
                secretKeyRef:
                  name: helm-m2-flask-helm-m1-secrets
                  key: API_TOKEN

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
---
# Source: flask-helm-m1/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: helm-m2-flask-helm-m1
  labels:
    helm.sh/chart: flask-helm-m1-0.2.0
    app.kubernetes.io/name: flask-helm-m1
    app.kubernetes.io/instance: helm-m2
    app.kubernetes.io/version: "1.1.0"
    app.kubernetes.io/managed-by: Helm
spec:
  ingressClassName: nginx
  rules:
    - host: "example.com"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: helm-m2-flask-helm-m1
                port:
                  number: 5000
  ```
  ---

Confirmed that the env entries use `name: helm-m2-flask-helm-m1-secrets` per fullname helper, for using the release name `helm-m2`.

---

## Verification Notes

- `helm lint .` passed without errors.
- With default values (`ingress.enabled=false`), `helm template .` did not render any Ingress resource.
- When `ingress.enabled=true` was provided, an Ingress manifest was rendered.
- The deployment manifest included environment variables from an external Secret named `<release_name>-flask-helm-m1-secrets`.
- Keys defined under `.Values.secretEnvKeys` (`API_KEY`, `API_TOKEN`) appeared in the Deployment env section with proper `secretKeyRef` entries.
- Service type remained **ClusterIP** and exposed the Flask app on port `5000`, which is consistent with Helm-M-1.

---


