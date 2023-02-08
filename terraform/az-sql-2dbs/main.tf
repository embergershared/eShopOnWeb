# Overview:
#   This module:
#   - Creates 2 Azure SQL databases.


#
# - Dependencies data resources
#
locals {
  rg_name = "rg-cpchem-${var.team_name}-${var.iterator}"
}

data "azurerm_mssql_server" "this" {
  name                = lower("sqlsvr-cpchem-${var.team_name}-${var.iterator}")
  resource_group_name = local.rg_name
}


#--------------------------------------------------------------
#  Creating 2 SQL Databases
#--------------------------------------------------------------
resource "azurerm_mssql_database" "eshopweb_catalog" {
  name                  = lower("sqldb-cpchem-${var.team_name}-${var.iterator}-catalog")
  server_id             = data.azurerm_mssql_server.this.id
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  license_type          = "LicenseIncluded"
  max_size_gb           = 1
  read_scale            = false
  sku_name              = "S0"
  zone_redundant        = false
  storage_account_type  = "Local"
}
resource "azurerm_mssql_database" "eshopweb_identity" {
  name                  = lower("sqldb-cpchem-${var.team_name}-${var.iterator}-identity")
  server_id             = data.azurerm_mssql_server.this.id
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  license_type          = "LicenseIncluded"
  max_size_gb           = 1
  read_scale            = false
  sku_name              = "S0"
  zone_redundant        = false
  storage_account_type  = "Local"
}
#*/
