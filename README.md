# Deutsche Bank Merchant Solutions – Junior Position Solutions 

This repository contains Junior level solutions. I kept the task copies in `Junior/*` for submission and placed runnable GitHub Actions under `.github/workflows/`, so it can be tested in GitHub Actions CI in a private repo.

## Goals

* Keeping specific task folders (like `Junior/GHA-J-1`, `Helm-J-1`, `Helm-J-2`, `TF-J-1`) on **main**.
* Pushing other task folders (for example, `Junior/GHA-J-2`) to a **feature branch**.
* Confirming that multiple workflows can coexist under `.github/workflows/`.

## Repository layout

```
DB-Solutions/
  ├── .github/
  │   └── workflows/
  │       ├── gha-j-1.yml          # Workflow for GHA-J-1 
  │       ├── gha-j-2.yml          # Workflow for GHA-J-2 
  │       ├── int-j-1.yml          # Workflow for INT-J-1 
  └── Junior/
      ├── GHA-J-1/                 # Task folder for GHA-J-1 (on main)
      │   ├── README.md            
      │   └── solution.yml         # Solution workflow
      │
      ├── GHA-J-2/                 # Task folder for GHA-J-2 (on feature branch)
      │   ├── README.md            
      │   ├── solution.yml         # Docker Build Workflow solution
      │   └── prerequisites/       # Provided prerequisites
      │
      ├── INT-J-1/                 # Task folder for INT-J-1 (on main)
      │   ├── README.md
      │   ├── solution_terraform/  # Terraform solution folder
      │   │   ├── main.tf
      │   │   ├── variables.tf
      │   │   ├── versions.tf
      │   │   └── output.tf
      │   └── solution_helm/       # Helm solution folder
      │       └── helm-chart/
      │           ├── Chart.yaml
      │           ├── values.yaml
      │           └── templates/
      │               ├── _helpers.tpl
      │               └── deployment.yaml
      │
      ├── Helm-J-1/                # Task folder for Helm-J-1 (on main)
      │   ├── README.md
      │   └── solution_readme.md   # Solution for Helm-J-1
      │
      ├── Helm-J-2/                # Task folder for Helm-J-2 (on main)
      │   ├── README.md
      │   ├── solution_deployment.yaml  # Modified deployment template
      │   └── prerequisites/
      │       └── helm-chart/      # Provided helm-chart prerequisites
      │
      └── TF-J-1/                  # Task folder for TF-J-1   (on main)
          ├── README.md
          └── solution_main.tf     # Terraform main solution file (with included solution)
```
## Tasks Overview

- [GHA-J-1](Junior/GHA-J-1/README.md)
- [GHA-J-2](Junior/GHA-J-2/README.md)
- [INT-J-1](Junior/INT-J-1/README.md)
- [Helm-J-1](Junior/Helm-J-1/README.md)
- [Helm-J-2](Junior/Helm-J-2/README.md)
- [TF-J-1](Junior/TF-J-1/README.md)

## Github Repository Setup
```bash
echo "# DB-Solutions" >> README.md
git init
git add README.md
git commit -m "First commit" 
git branch -M main
git remote add origin git@github.com:rubak714/DB-Solutions.git
git push -u origin main

# during switching to a feature branch for GHA-J-2
git checkout -b feature/GHA-J-2
git commit -m "Adding GHA-J-2 solution and its workflow"
# pushing to the feature branch
git push -u origin feature/GHA-J-2
```

## Final Observations
- GitHub Actions
  - `GHA-J-1` workflow > prints on push to `main`
  - `GHA-J-2` workflow > builds the image or blueprint from Dockerfile on `feature/*` branch.
  - `INT-J-1` workflow > validates Terraform and creates bucket in GCP and renders the Helm chart.
- Helm
  - `Helm-J-1` readme with the simulated `bitnami/nginx` install command  
    **Verification (Helm-J-1):** Yes, the Helm command is correct. It installs `bitnami/nginx` into a `webserver` namespace with `service.type` overridden to `LoadBalancer`.  
    *Command used:*
    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    helm upgrade --install nginx bitnami/nginx \
      --namespace webserver \
      --create-namespace \
      --set service.type=LoadBalancer
    ```
    *After Running:*
    ```bash
    kubectl get pods -n webserver # confirming the nginx Pods were deployed and are in a running state
    kubectl get svc -n webserver # confirming the nginx Service > LoadBalancer was created

    ```
    *Confirming override:*
    ```bash
    helm get values -n webserver nginx # verifying that the override (service.type=LoadBalancer) was applied
    ```

  - `Helm-J-2` with updated `deployment.yaml` 
  **Verification (Helm-J-2):**
    - Yes: added app.kubernetes.io/managed-by: "helm" under spec.template.metadata.labels (Pod level).
    - Yes: `helm template .` shows the label in the rendered Deployment manifest.
    - In short, added Pod label, bumped chart to 0.1.1, aligned appVersion to 1.25-alpine.

  - `INT-J-1/solution_helm/helm-chart/` with a simple chart that exposes `GREETING_MESSAGE`

- Terraform
  - `TF-J-1` and `TF-J-2` with bucket creation (with unique name) and output
  - `INT-J-1` with bucket creation (with unique name) having `config/settings.txt` object inside
  