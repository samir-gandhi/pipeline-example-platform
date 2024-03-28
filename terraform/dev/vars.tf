variable "pingone_username" {
  default = ""
}
variable "pingone_password" {
  default = ""
}
variable "pingone_region" {
  default = ""
}
variable "pingone_client_id" {
  default = ""
}
variable "pingone_client_secret" {
  default = ""
}
variable "pingone_environment_id" {
  default = ""
}
variable "pingone_environment_name" {
  description = "name that will be used when creating PingOne Environment"
}
variable "pingone_environment_type" {
  default = ""
}
variable "pingone_license_id" {
  default = ""
}

### dev on demand vars
variable "tf_state_bucket" {
  default = "ping-terraform-demo"
}

variable "tf_state_region" {
  default = "us-west-1"
}

variable "tf_state_key" {
}