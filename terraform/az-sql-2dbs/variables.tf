variable spn_tenant_id       {}
variable spn_subscription_id {}
variable spn_client_id       {}
variable spn_secret          {}


#   General settings
variable "team_name" {}
variable iterator {
  type = string
  description = "Iterator to be added to all created resources"
  default = "01"
}

