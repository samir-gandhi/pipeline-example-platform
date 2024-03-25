terraform {
  backend "s3" {
    bucket = "ping-terraform-demo"
    key    = "dev"
    region = "us-west-1"
  }
}

module "base" {
  source = "../"
  pingone_username = var.pingone_username
  pingone_password = var.pingone_password
  pingone_region = var.pingone_region
  pingone_client_id = var.pingone_client_id
  pingone_client_secret = var.pingone_client_secret
  pingone_environment_id = var.pingone_environment_id
  pingone_environment_name = var.pingone_environment_name
  pingone_environment_type = var.pingone_environment_type
  pingone_license_id = var.pingone_license_id
}