# Task (TF-J-1): Create GCS Bucket

*   **Use Case:** Write Terraform code (`main.tf`) to create a Google Cloud Storage (GCS) bucket in a specific region (e.g., `europe-west3`). The bucket name should be unique (e.g., by appending a random ID or using the project ID).
*   **Verification:** Is the Terraform code valid? Does it define a GCS bucket with the required attributes?
*   **Solution:** Place in: `/Junior/TF-J-1/solution_main.tf`

# Task (TF-J-2): Use Terraform Output

*   **Use Case:** Extend the Terraform code from TF-J-1 to output the name of the created GCS bucket using an `output` variable.
*   **Verification:** Does `terraform output bucket_name` display the correct bucket name after applying?
*   **Solution:** (Included in solution for TF-J-1) Place in: `/Junior/TF-J-1/solution_main.tf`

# *Solutions: TF-J-1 and TF-J-2 > Create a unique GCS bucket and Terraform Output*

## Task Layout

```
Junior/TF-J-1/
  ├── solution_main.tf
  └── README.md
```

---

# Step-by-Step Execution 

## 1. `solution_main.tf` script

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

# generating a random hex suffix to ensure bucket name uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}

# TF-J-1: Create a unique GCS bucket
# Verification:
# - Code is valid (passes terraform validate)
# - Creates a GCS bucket in europe-west3
# - Name is unique via random_id
# - Uses uniform bucket-level access and force_destroy for cleanup

resource "google_storage_bucket" "bucket" {
  name                        = "db-ms-tf-j-1-${random_id.suffix.hex}"
  location                    = "europe-west3"
  uniform_bucket_level_access = true
  force_destroy               = true
}

# TF-J-2: Output the bucket name
# Verification:
# - terraform output bucket_name displays the correct bucket name

output "bucket_name" {
  value       = google_storage_bucket.bucket.name
  description = "Name of the created GCS bucket"
}
```

---

## 2. Validated without applying (without GCP credentials)

```bash
cd Junior/TF-J-1
terraform init -backend=false
terraform validate # Output> Success! The configuration is valid.
```
---

## 3. Validated with applying (with GCP credentials)
```bash
gcloud auth application-default login   
terraform apply -auto-approve -var="project_id=stable-healer-418019" # Output> Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
terraform output bucket_name # Output> "db-ms-tf-j-1-11d904b1"
```
---

## Verification Note

- The Terraform code is valid. The configuration passed `terraform validate`. It defines a `google_storage_bucket` with `location = "europe-west3"`, `force_destroy = true` and a unique name using `random_id`.

- Currect bucket name was observed. After running `terraform apply` and `terraform output bucket_name`, it returned the generated bucket name in the format `db-ms-tf-j-1-11d904b1`.

---