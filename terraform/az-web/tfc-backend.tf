terraform {
  backend "remote" {
    organization = "embergerimmdays"

    workspaces {
      name = "eShopOnWeb-05-AppServiceWeb"
    }
  }
}