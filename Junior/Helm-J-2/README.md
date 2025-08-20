# Task (Helm-J-2): Modify Simple Template

*   **Use Case:** Given a simple Helm chart (provided in folder: `/Junior/Helm-J-2/prerequisites/helm-chart/`), modify the `deployment.yaml` template to add an additional label `app.kubernetes.io/managed-by: helm` to the Pods.
*   **Verification:** Is the label correctly added in the rendered manifest (`helm template .`)?
*   **Solution:** Place in: `/Junior/Helm-J-2/solution_deployment.yaml` (showing the modified template)
*   **Prerequisites:** See files in : `/Junior/Helm-J-2/prerequisites/helm-chart/`

---

# Solutions: Helm-J-2 > Modified simple Helm chart 

## Task Layout

```
Junior/Helm-J-2/                
  ├── solution_deployment.yaml          # Modified deployment template 
  └── prerequisites/
      └── helm-chart/                   # Provided helm-chart prerequisites
          ├── Chart.yaml                
          ├── values.yaml               
          └── templates/                
              ├── _helpers.tpl          
              └── deployment.yaml       
```
---

## Step-by-Step Execution

## 1. Overview of the Task

The **Helm-J-2** task requires:

* Using an existing minimal NGINX Helm chart.
* Adding the label `app.kubernetes.io/managed-by: "helm"` **at the Pod level** (`spec.template.metadata.labels`).
* Keeping the rest of the chart functional.

---

## 3. Added required Pod label

**File:** `templates/deployment.yaml`

```yaml
spec:
  template:
    metadata:
      labels:
        {{- include "simple-nginx-chart.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/managed-by: "helm"
```

Integrated the label **only at Pod level** (`spec.template.metadata.labels`). This finally ensured that only the **Pod** has the required label.

---

## 4. Preserved all original chart helpers

The `_helpers.tpl` functions remain unchanged.

For testing, the working Helm chart was under `prerequisites/helm-chart/` and the same modified deployment file was placed in `Helm-J-2/` as final solution file >`solution_deployment.yaml`.

---

## 5. Tested the modified chart and it was run from the chart root

Bumped the chart version to `0.1.1` and set appVersion to match the NGINX tag, i was using by default. The linting was successful and `grep -n` helped quickly check if the label I added (in `deployment.yaml` pod template metadata),
actually appeared in the rendered Kubernetes manifest or not.

```bash
cd Junior/Helm-J-2/prerequisites/helm-chart
helm lint --debug .
helm template . | grep -n "app.kubernetes.io/managed-by"
```
---

## 6. Final Results

```bash
rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/db_ms_junior_solutions/Junior/Helm-J-2/prerequisites/helm-chart  
$ helm lint --debug .
==> Linting .
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/Helm-J-2/prerequisites/helm-chart  
$ helm template . | grep -n "app.kubernetes.io/version"
11:    app.kubernetes.io/version: "1.25-alpine"

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/Helm-J-2/prerequisites/helm-chart  
$ helm template . | grep -n "image:"
33:          image: "nginx:1.25-alpine"

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/Helm-J-2/prerequisites/helm-chart  
$ helm template .
```

The `helm template . ` showed that the label was added correctly in the rendered manifest as shown below.

```bash
# Output> Source: simple-nginx-chart/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: release-name-simple-nginx-chart
  labels:
    helm.sh/chart: simple-nginx-chart-0.1.1
    app.kubernetes.io/name: simple-nginx-chart
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.25-alpine"
    app.kubernetes.io/managed-by: Helm
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: simple-nginx-chart
      app.kubernetes.io/instance: release-name
  template:
    metadata:
      labels:
        app.kubernetes.io/name: simple-nginx-chart
        app.kubernetes.io/instance: release-name
        app.kubernetes.io/managed-by: "helm"  # added successfully
    spec:
      serviceAccountName: release-name-simple-nginx-chart
      securityContext:
        {}
      containers:
        - name: simple-nginx-chart
          securityContext:
            {}
          image: "nginx:1.25-alpine"
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: http
          readinessProbe:
            httpGet:
              path: /
              port: http
          resources:
            {}
```
---

## Verification Note:

- `helm lint --debug` passed without errors.
- In rendered manifest, the `app.kubernetes.io/managed-by: helm` label appeared **only under `spec.template.metadata.labels`**.
- The labels in `spec.template.metadata.labels` were applied to the Pods themselves.

---

