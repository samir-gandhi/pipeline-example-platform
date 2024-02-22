terraform {
  required_providers {
    pingone = {
      source = "pingidentity/pingone"
    }
    davinci = {
      source = "pingidentity/davinci"
    }
  }
}


provider "pingone" {
  client_id = var.pingone_client_id
  client_secret = var.pingone_client_secret
  environment_id = var.pingone_environment_id
  region         = var.pingone_region
  force_delete_production_type = false
}

provider "davinci" {
  username = var.pingone_username
  password = var.pingone_password
  environment_id = var.pingone_environment_id
  region = var.pingone_region
}

data "pingone_environment" "admin_environment" {
  environment_id = var.pingone_environment_id
}

# Find license based on license name

data "pingone_licenses" "internal" {
  organization_id = data.pingone_environment.admin_environment.organization_id

  data_filter {
    name = "name"
    values = [
      "INTERNAL"
    ]
  }

  data_filter {
    name   = "status"
    values = ["ACTIVE"]
  }
}

resource "pingone_environment" "environment" {
  name        = var.environment_name
  description = "BXI Dev"
  type        = "SANDBOX"
  license_id  = data.pingone_licenses.internal.ids[0]



  service {
    type = "SSO"
  }
  service {
    type = "MFA"
  }
  service {
    type = "DaVinci"
  }

}

resource "pingone_population_default" "default_population" {
  environment_id = resource.pingone_environment.environment.id
  name        = "My Population"
  description = "My new population for users"
}

data "pingone_role" "davinci_admin" {
  name = "DaVinci Admin"
}

data "pingone_role" "identity_data_admin" {
  name = "Identity Data Admin"
}

data "pingone_role" "environment_admin" {
  name = "Environment Admin"
}

data "pingone_user" "admin_user" {
  environment_id = var.pingone_environment_id
  username       = var.pingone_username
}

resource "pingone_role_assignment_user" "davinci_admin_sso" {
  environment_id       = var.pingone_environment_id
  user_id              = data.pingone_user.admin_user.id
  role_id              = data.pingone_role.davinci_admin.id
  scope_environment_id = resource.pingone_environment.environment.id
}

resource "pingone_role_assignment_user" "identity_data_admin_sso" {
  environment_id       = var.pingone_environment_id
  user_id              = data.pingone_user.admin_user.id
  role_id              = data.pingone_role.identity_data_admin.id
  scope_environment_id = resource.pingone_environment.environment.id
}

resource "pingone_role_assignment_user" "environment_admin_sso" {
  environment_id       = var.pingone_environment_id
  user_id              = data.pingone_user.admin_user.id
  role_id              = data.pingone_role.environment_admin.id
  scope_environment_id = resource.pingone_environment.environment.id
}

resource "pingone_population" "customers" {
  environment_id = resource.pingone_environment.environment.id

  name        = "Customers"
  description = "Customer Identities"
}

resource "pingone_application" "worker" {
  environment_id = resource.pingone_environment.environment.id
  name           = "dv-connection"
  enabled        = true

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_authn_method = "CLIENT_SECRET_BASIC"
  }
}

resource "pingone_application_role_assignment" "worker_app_davinci_admin_role" {
  environment_id       = pingone_environment.environment.id
  application_id       = pingone_application.worker.id
  role_id              = data.pingone_role.davinci_admin.id
  scope_environment_id = pingone_environment.environment.id
}

resource "pingone_application_role_assignment" "worker_app_identity_data_admin_role" {
  environment_id       = pingone_environment.environment.id
  application_id       = pingone_application.worker.id
  role_id              = data.pingone_role.identity_data_admin.id
  scope_environment_id = pingone_environment.environment.id
}

resource "pingone_application_role_assignment" "worker_app_environment_admin_role" {
  environment_id       = pingone_environment.environment.id
  application_id       = pingone_application.worker.id
  role_id              = data.pingone_role.environment_admin.id
  scope_environment_id = pingone_environment.environment.id
}

resource "pingone_mfa_policy" "standard" {
  environment_id = pingone_environment.environment.id
  name           = "standard"

  mobile {
    enabled = false
  }

  totp {
    enabled = true
  }

  # security_key {
  #   enabled = true
  # }

  # platform {
  #   enabled = true
  # }

  sms {
    enabled = false
  }

  voice {
    enabled = false
  }

  email {
    enabled = true
  }

}

data "davinci_connections" "all" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  depends_on = [
    resource.pingone_role_assignment_user.environment_admin_sso
  ]
}

resource "davinci_variable" "population" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  depends_on     = [data.davinci_connections.all]
  name = "populationId"
  context = "company"
  description = "pingone customers population id"
  type = "string"
  value = resource.pingone_population.customers.id
  mutable = false
}

resource "davinci_variable" "agreement" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  depends_on     = [data.davinci_connections.all]
  name = "agreementId"
  context = "company"
  description = "some agreement.."
  type = "string"
  value = "abc123"
  mutable = false
}

resource "davinci_flow" "bxi_registration" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  flow_json = file("${path.module}/BXI-Registration.json")
  depends_on = [data.davinci_connections.all, davinci_variable.population, davinci_variable.agreement]

  connection_link {
    name = "PingOne"
    id = "94141bf2f1b9b59a5f5365ff135e02bb"
  }
  connection_link {
    name = "Http"
    id = "867ed4363b2bc21c860085ad2baa817d"
  }
  connection_link {
    name = "Annotation"
    id = "921bfae85c38ed45045e07be703d86b8"
  }
  connection_link {
    name = "Variables"
    id = "06922a684039827499bdbdd97f49827b"
  }
  connection_link {
    name = "Error Message"
    id = "53ab83a4a4ab919d9f2cb02d9e111ac8"
  }
  connection_link {
    name = "PingOne MFA"
    id = "b72bd44e6be8180bd5988ac74cd9c949"
  }
}

resource "davinci_flow" "bxi_authentication" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  flow_json = file("${path.module}/BXI-Authentication.json")
  depends_on = [data.davinci_connections.all, davinci_variable.population, davinci_variable.agreement]
  connection_link {
    name = "PingOne"
    id = "94141bf2f1b9b59a5f5365ff135e02bb"
  }
  connection_link {
    name = "Http"
    id = "867ed4363b2bc21c860085ad2baa817d"
  }
  connection_link {
    name = "Annotation"
    id = "921bfae85c38ed45045e07be703d86b8"
  }
  connection_link {
    name = "Variables"
    id = "06922a684039827499bdbdd97f49827b"
  }
  connection_link {
    name = "Error Message"
    id = "53ab83a4a4ab919d9f2cb02d9e111ac8"
  }
  connection_link {
    name = "Functions"
    id = "de650ca45593b82c49064ead10b9fe17"
  }
  connection_link {
    id = "e7eae662d2ca276e4c6f097fc36a3bb1"
    name = "Node"
  }
  connection_link {
    name = "PingOne MFA"
    id = "b72bd44e6be8180bd5988ac74cd9c949"
  }
}

resource "davinci_application" "bxi_app" {
  environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
  name           = "BXI App"
  oauth {
    enabled = true
    values {
      allowed_grants                = ["authorizationCode"]
      allowed_scopes                = ["openid", "profile"]
      enabled                       = true
      enforce_signed_request_openid = false
    }
  }
  saml {
    values {
      enabled                = false
      enforce_signed_request = true
    }
  }

  depends_on = [
    data.davinci_connections.all
  ]
}

resource "davinci_application_flow_policy" "registration" {
    environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
    application_id = resource.davinci_application.bxi_app.id
    name = "Registration"
    policy_flow {
      flow_id    = resource.davinci_flow.bxi_registration.id
      version_id = -1
      weight     = 100
    }
}

resource "davinci_application_flow_policy" "authentication" {
    environment_id = resource.pingone_role_assignment_user.davinci_admin_sso.scope_environment_id
    application_id = resource.davinci_application.bxi_app.id
    name = "Authentication"
    policy_flow {
      flow_id    = resource.davinci_flow.bxi_authentication.id
      version_id = -1
      weight     = 100
    }
}

output "app_policies" {
  # value = {for i in resource.davinci_application.bxi_app.policies : "${i.name}" => i.policy_id}
  value = [{"bxi_registration_policy_id"=resource.davinci_application_flow_policy.registration.id}, {"bxi_login_policy_id"=resource.davinci_application_flow_policy.authentication.id}]
  sensitive = true
}

output "bxi_api_key" {
  value = resource.davinci_application.bxi_app.api_keys.prod
  sensitive = true
}

output "bxi_api_url" {
  value = format("https://auth.pingone.%s", 
    coalesce(
      resource.pingone_environment.environment.region == "Europe" ? "eu" :"",
      resource.pingone_environment.environment.region == "AsiaPacific" ? "asia" :"",
      resource.pingone_environment.environment.region == "Canada" ? "ca" :"",
      resource.pingone_environment.environment.region == "NorthAmerica" ? "com" :"",
    )
  )
}

output "bxi_sdk_token_url" {
  value = format("https://orchestrate-api.pingone.%s", coalesce(
    resource.pingone_environment.environment.region == "Europe" ? "eu" :"",
    resource.pingone_environment.environment.region == "AsiaPacific" ? "asia" :"",
    resource.pingone_environment.environment.region == "Canada" ? "ca" :"",
    resource.pingone_environment.environment.region == "NorthAmerica" ? "com" :"",
    ))
}

output "bxi_company_id" {
  value = resource.pingone_environment.environment.id
}
