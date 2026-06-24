resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = local.tags
}

resource "azurerm_linux_web_app" "app" {
  name                = "app-${local.prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id
  tags                = local.tags

  site_config {
    application_stack {
      python_version = "3.11"
    }
    always_on        = false
    app_command_line = "gunicorn --bind=0.0.0.0:8000 --workers=2 app:app"
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    SQL_SERVER   = azurerm_mssql_server.sql.fully_qualified_domain_name
    SQL_DATABASE = azurerm_mssql_database.db.name
    SQL_USER     = var.sql_admin_login
    SQL_PASSWORD = var.sql_admin_password
  }

  identity {
    type = "SystemAssigned"
  }
}
