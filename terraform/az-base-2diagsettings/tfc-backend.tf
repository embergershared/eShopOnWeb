terraform {
  backend "remote" {
    organization = "embergerimmdays"

    workspaces {
      name = "eShopOnWeb-02-Base-DiagnosticSettings"
    }
  }
}