# Overview:
#   This module:
#   - Creates an Azure SQL Server with Encryption and Security,


#
# - Dependencies data resources
#
locals {
  rg_name = "rg-cpchem-${var.team_name}-${var.iterator}"
  kv_name = "kv-cpchem-${var.team_name}-${var.iterator}"
}

data "azurerm_resource_group" "this" {
  name = local.rg_name
}

data "azurerm_key_vault" "this" {
  name                = local.kv_name
  resource_group_name = local.rg_name
}


# -
# - Get the current user config
# -
data "azurerm_client_config" "current" {}

# -
# - Generate random password for the SQL server
# -
resource "random_password" "this" {
  length           = 32
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  numeric          = true
  special          = true
  override_special = "!@$%*()-_=+[]{}:?"
}

# 
# - Get the SQL Server name with Wells Fargo module
# 

locals {
  administrator_login_password = random_password.this.result

  key_permissions         = ["get", "wrapkey", "unwrapkey"]
  secret_permissions      = ["get"]
  certificate_permissions = ["get"]
  storage_permissions     = ["get"]

  tags = merge(
    data.azurerm_resource_group.this.tags,
    var.additional_tags
  )
}

# -
# - Azure SQL Server
# -
resource "azurerm_mssql_server" "this" {
  name                                 = lower("sqlsvr-cpchem-${var.team_name}-${var.iterator}")
  resource_group_name                  = data.azurerm_resource_group.this.name
  location                             = data.azurerm_resource_group.this.location
  version                              = var.azuresql_version
  administrator_login                  = var.administrator_login_name
  administrator_login_password         = local.administrator_login_password
  connection_policy                    = var.connection_policy
  outbound_network_restriction_enabled = var.outbound_network_restriction_enabled

  # - Azure Deny Public Network Access - Hardcoded
  public_network_access_enabled = true
  
  # Encryption in transit.
  minimum_tls_version = "1.2"
  dynamic "identity" {
    for_each = var.assign_identity == false ? [] : tolist([var.assign_identity])
    content {
      type = "SystemAssigned"
    }
  }
  lifecycle {
    ignore_changes = [administrator_login_password]
  }
  tags = local.tags
}

# -
# - Add Azure SQL Admin Login Password to Key Vault secrets
# -
resource "azurerm_key_vault_secret" "azuresql_keyvault_secret" {
  name         = azurerm_mssql_server.this.name
  value        = local.administrator_login_password
  key_vault_id = data.azurerm_key_vault.this.id
  depends_on   = [azurerm_mssql_server.this]
}

#----------------------------------------------------------------------------------------------------------------------
# - Assigning Key Vault Crypto Service Encryption User to system assigned identity using wf-role-assignment module
#----------------------------------------------------------------------------------------------------------------------
# - Grant Key Vault permissions to the server
resource azurerm_role_assignment sql-enc {
  count                            = var.cmk_enabled_transparent_data_encryption == true ? 1 : 0

  scope                            = data.azurerm_key_vault.this.id
  role_definition_name             = "Key Vault Crypto Service Encryption User"
  principal_id                     = azurerm_mssql_server.this.identity.0.principal_id
  skip_service_principal_aad_check = true
  description                      = "Assigning the `Key Vault Crypto Service Encryption User` role to the service identity to allow its access to the key vault keys."

  depends_on = [
    azurerm_key_vault_key.primary
  ]
}


# -
# - Generate CMK Key for Azure Sql Server
# - 
resource "azurerm_key_vault_key" "primary" {
  count        = var.cmk_enabled_transparent_data_encryption == true ? 1 : 0
  name         = format("%s-key", azurerm_mssql_server.this.name)
  key_vault_id = data.azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 2048 # The supported RSA Key Size is 2048 or 3072 and Key Type is RSA or RSA-HSM."

  key_opts = [
    "decrypt", "encrypt", "sign",
    "unwrapKey", "verify", "wrapKey"
  ]
}

# -
# - Add the Key Vault key to the server and set the TDE Protector
# - Turn on TDE (Transparent Data Encryption)
# -
resource "azurerm_mssql_server_transparent_data_encryption" "this" {
  server_id        = azurerm_mssql_server.this.id
  key_vault_key_id = azurerm_key_vault_key.primary.0.id

  depends_on = [azurerm_mssql_server.this]
}

# -
# - Allow access to SQL Server from the Azure Services
# -
resource azurerm_mssql_firewall_rule this {
  name                = "AllowAzureServicesAccess"
  server_id           = azurerm_mssql_server.this.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

/*
#--------------------------------------------------------------
#  Creating 2 SQL Databases
#--------------------------------------------------------------
resource "azurerm_mssql_database" "eshopweb_catalog" {
  name                  = lower("sqldb-cpchem-${var.team_name}-${var.iterator}-catalog")
  server_id             = azurerm_mssql_server.this.id
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
  server_id             = azurerm_mssql_server.this.id
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  license_type          = "LicenseIncluded"
  max_size_gb           = 1
  read_scale            = false
  sku_name              = "S0"
  zone_redundant        = false
  storage_account_type  = "Local"
}
#*/
