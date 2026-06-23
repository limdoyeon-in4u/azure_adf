resource "azurerm_data_factory" "adf" {
  name                = "adf-${local.prefix}-${local.suffix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

# ADF에 Storage Blob Data Contributor 권한 부여
resource "azurerm_role_assignment" "adf_storage" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

# Linked Service - Azure Blob Storage (MSI 인증)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "ls_blob" {
  name              = "ls_blob_raw"
  data_factory_id   = azurerm_data_factory.adf.id
  service_endpoint  = azurerm_storage_account.sa.primary_blob_endpoint
  use_managed_identity = true
}

# Linked Service - Azure SQL Database
resource "azurerm_data_factory_linked_service_azure_sql_database" "ls_sql" {
  name            = "ls_azure_sql"
  data_factory_id = azurerm_data_factory.adf.id
  connection_string = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.db.name};User ID=${var.sql_admin_login};Password=${var.sql_admin_password};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# Dataset - CSV (Blob Source)
resource "azurerm_data_factory_dataset_delimited_text" "ds_csv" {
  name                = "ds_ar_csv"
  data_factory_id     = azurerm_data_factory.adf.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.ls_blob.name

  azure_blob_storage_location {
    container = azurerm_storage_container.raw.name
    path      = ""
    filename  = "ar_data.csv"
  }

  column_delimiter    = ","
  row_delimiter       = "\r\n"
  encoding            = "UTF-8"
  first_row_as_header = true
}

# Dataset - Azure SQL (Sink) — custom dataset으로 테이블명 직접 지정
resource "azurerm_data_factory_custom_dataset" "ds_sql" {
  name            = "ds_ar_sql"
  data_factory_id = azurerm_data_factory.adf.id
  type            = "AzureSqlTable"

  linked_service {
    name = azurerm_data_factory_linked_service_azure_sql_database.ls_sql.name
  }

  type_properties_json = jsonencode({
    tableName = "dbo.AR_RECEIVABLES"
  })
}

# Pipeline - CSV → SQL Copy
resource "azurerm_data_factory_pipeline" "pipeline_copy" {
  name            = "pl_copy_ar_csv_to_sql"
  data_factory_id = azurerm_data_factory.adf.id

  activities_json = jsonencode([
    {
      name = "CopyARData"
      type = "Copy"
      inputs = [{ referenceName = azurerm_data_factory_dataset_delimited_text.ds_csv.name, type = "DatasetReference" }]
      outputs = [{ referenceName = azurerm_data_factory_custom_dataset.ds_sql.name, type = "DatasetReference" }]
      typeProperties = {
        source = {
          type = "DelimitedTextSource"
          storeSettings = { type = "AzureBlobStorageReadSettings", recursive = false }
          formatSettings = { type = "DelimitedTextReadSettings" }
        }
        sink = {
          type             = "AzureSqlSink"
          writeBehavior    = "insert"
          preCopyScript    = "TRUNCATE TABLE dbo.AR_RECEIVABLES"
          disableMetricsCollection = false
        }
        enableStaging = false
      }
    }
  ])
}
