# /Mid-Level/GHA-M-2/solution_backend.tf

terraform {
  backend "remote" {
    organization = "db-solutions-org"   # TFC org

    workspaces {
      name = "gha-m-2-workspace"        # TFC workspace
    }
  }
}
