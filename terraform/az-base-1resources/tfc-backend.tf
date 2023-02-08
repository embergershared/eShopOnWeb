terraform {
  backend "remote" {
    organization = "embergerimmdays"

    workspaces {
      name = "eShopOnWeb-01-Base-Resources"
    }
  }
}