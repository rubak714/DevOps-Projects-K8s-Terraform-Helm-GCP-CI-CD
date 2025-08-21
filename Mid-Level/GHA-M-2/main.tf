# minimal resource to demonstrate plan/apply
resource "local_file" "example" {
  filename = "example.txt"
  content  = "Hello from Terraform Cloud workflow"
}
