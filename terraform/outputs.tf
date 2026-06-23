output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "storage_container_name" {
  value = azurerm_storage_container.raw.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_mssql_database.db.name
}

output "adf_name" {
  value = azurerm_data_factory.adf.name
}

output "app_service_url" {
  value = "https://${azurerm_linux_web_app.app.default_hostname}"
}
