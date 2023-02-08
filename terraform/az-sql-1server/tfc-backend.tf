terraform {
  backend "remote" {
    organization = "embergerimmdays"

    workspaces {
      name = "eShopOnWeb-03-AzureSQLServer"
    }
  }
}