# Task (Helm-J-1): Install Existing Chart (Simulated)

*   **Use Case:** Write a Helm command (or a small script) to simulate the installation of the official `bitnami/nginx` chart into a namespace named `webserver`. Override the `service.type` to `LoadBalancer`. Document the command in your main `README.md`.
*   **Verification:** Is the Helm command correct? Is the value correctly overridden? Is the command documented?
*   **Solution:** Place in: `/Junior/Helm-J-1/solution_readme.md`

--- 

# *Solutions: Helm-J-1 > Installed bitnami/nginx into `webserver` (simulated)*

## Task Layout

```
Junior/Helm-J-1/                
  └── solution_readme.md
```

---

## Step-by-Step Execution (kubectl, Helm and Minikube via curl)

## 1. Created a tools folder

```bash
mkdir -p "C:/Users/rubai/OneDrive/Desktop/kubetools"
cd "C:/Users/rubai/OneDrive/Desktop/kubetools"
```
---

## 2. Installed kubectl

```bash
curl -LO "https://dl.k8s.io/release/v1.31.0/bin/windows/amd64/kubectl.exe"
```
---

## 3. Installed Helm

```bash
curl -LO "https://get.helm.sh/helm-v3.14.4-windows-amd64.zip"
unzip helm-v3.14.4-windows-amd64.zip
mv windows-amd64/helm.exe ./helm.exe
rm -rf windows-amd64 helm-v3.14.4-windows-amd64.zip
```
---

## 4. Installed Minikube (for local cluster)

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-windows-amd64.exe
mv minikube-windows-amd64.exe minikube.exe
```
---

## 5. Added to PATH

* After going to **Environment Variables** → Edited **System variables** → Added path of `/kubetools`.

---

## 6. Verified Installations

```bash
kubectl version --client
helm version
minikube version  
```
---

## 7. Added Bitnami repo and update (Found error while running below commands)

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
---

## 8. Verified my current kube context and removed stale old GKE context (since the cluster was deleted in GCP)

```bash
kubectl config current-context
kubectl config delete-context gke_stable-healer-418019_europe-west2_my-cluster
kubectl config delete-user gke_stable-healer-418019_europe-west2_my-cluster
kubectl config unset current-context
kubectl config get-contexts
```
---

```bash
minikube start --driver=docker
minikube status
kubectl config current-context
kubectl cluster-info
kubectl get nodes
```
---

## 9. Re-run Helm command and Simulated Install of `bitnami/nginx` into `webserver` namespace

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install nginx bitnami/nginx \
  --namespace webserver \
  --create-namespace \
  --set service.type=LoadBalancer

kubectl get pods -n webserver
kubectl get svc -n webserver
```
---

The Service is type: LoadBalancer, but my cluster was not providing a cloud based load balancer. 
And these fixes usually depend on where I am running the cluster. As this was running on **minikube** , so I used `minikube tunnel`.

## 10. Deployed something and exposed as LoadBalancer

```bash
kubectl create deployment hello --image=nginx:1.25-alpine
kubectl expose deployment hello --type=LoadBalancer --port=80 --target-port=80
kubectl get svc hello
```
---

## 11. Ran the tunnel in an elevated PowerShell and kept it open

```bash
Start-Process -Verb RunAs powershell -ArgumentList '-NoExit','-Command', 'minikube tunnel'
```
---

## 12. Verified on the Service (Load Balancer)

```bash
kubectl get svc hello -w

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions
$ kubectl get svc hello
NAME    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
hello   LoadBalancer   10.106.137.63   127.0.0.1     80:32404/TCP   10m

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions
$ kubectl get svc -n webserver
NAME    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
nginx   LoadBalancer   10.107.181.78   127.0.0.1     80:30663/TCP,443:32544/TCP   6d1h
```
---

## 13. Validation

**Checked valid keys in chart values:**

```bash
helm show values bitnami/nginx | grep -n "service:"
```

**Verified the override after install:**

```bash
helm get values -n webserver nginx
```
---

## 14. Final Results

```bash
rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/Helm-J-1
$ helm show values bitnami/nginx | grep -n "service:"
671:service:
1034:  service:

rubai@Rubaiya-2023 MINGW64 ~/OneDrive/Desktop/DB/solutions/Junior/Helm-J-1
$ helm get values -n webserver nginx
USER-SUPPLIED VALUES:
service:
  type: LoadBalancer
```
---

## Verification Note

- The `helm upgrade --install` command for `bitnami/nginx` in the `webserver` namespace ran successfully.  
- The `service.type=LoadBalancer` override was explicitly done and confirmed via `helm get values -n webserver nginx`.  
- The entire command sequence, including installation steps, Helm usage, Minikube tunnel setup and value validation, has been clearly documented.  

---