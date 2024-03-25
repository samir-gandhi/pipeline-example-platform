provider "pingone" {
  client_id                    = var.pingone_client_id
  client_secret                = var.pingone_client_secret
  environment_id               = var.pingone_environment_id
  region                       = var.pingone_region
  force_delete_production_type = false
}

provider "davinci" {
  username       = var.pingone_username
  password       = var.pingone_password
  region         = var.pingone_region
  environment_id = var.pingone_environment_id
}