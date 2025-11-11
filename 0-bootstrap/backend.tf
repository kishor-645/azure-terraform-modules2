# Backend configuration for bootstrap
# Bootstrap uses local state since it creates the remote backend infrastructure
# After bootstrap, all other environments will use Azure Storage backend

terraform {
  # Local backend for bootstrap only
  backend "local" {
    path = "terraform.tfstate"
  }
}
