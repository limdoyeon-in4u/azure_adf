resource "azurerm_mssql_server" "sql" {
  name                         = "sql-${local.prefix}-${local.suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
  tags                         = local.tags
}

resource "azurerm_mssql_database" "db" {
  name      = "db-ar"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
  tags      = local.tags
}

# 로컬 IP 허용 (개발용)
resource "azurerm_mssql_firewall_rule" "local" {
  count            = var.my_ip != "" ? 1 : 0
  name             = "allow-local"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.my_ip
  end_ip_address   = var.my_ip
}

# Azure 서비스 허용 (ADF, App Service)
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
