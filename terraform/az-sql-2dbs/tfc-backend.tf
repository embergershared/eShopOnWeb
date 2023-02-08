terraform {
  backend "remote" {
    organization = "embergerimmdays"

    workspaces {
      name = "eShopOnWeb-04-AzureSQLDBs"
    }
  }
}