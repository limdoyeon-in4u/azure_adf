# Terraform override: adf.tf의 pipeline 리소스를 덮어씁니다
resource "azurerm_data_factory_pipeline" "pipeline_copy" {
  name            = "pl_copy_ar_csv_to_sql"
  data_factory_id = azurerm_data_factory.adf.id

  activities_json = jsonencode([
    {
      name    = "CopyToStaging"
      type    = "Copy"
      inputs  = [{ referenceName = azurerm_data_factory_dataset_delimited_text.ds_csv.name, type = "DatasetReference" }]
      outputs = [{ referenceName = azurerm_data_factory_custom_dataset.ds_staging.name, type = "DatasetReference" }]
      typeProperties = {
        source = {
          type           = "DelimitedTextSource"
          storeSettings  = { type = "AzureBlobStorageReadSettings", recursive = false }
          formatSettings = { type = "DelimitedTextReadSettings" }
        }
        sink = {
          type                     = "AzureSqlSink"
          writeBehavior            = "insert"
          preCopyScript            = "TRUNCATE TABLE dbo.AR_RECEIVABLES_STAGING"
          disableMetricsCollection = false
        }
        enableStaging = false
      }
    },
    {
      name      = "CopyViewToAR"
      type      = "Copy"
      dependsOn = [{ activity = "CopyToStaging", dependencyConditions = ["Succeeded"] }]
      inputs    = [{ referenceName = azurerm_data_factory_custom_dataset.ds_view.name, type = "DatasetReference" }]
      outputs   = [{ referenceName = azurerm_data_factory_custom_dataset.ds_sql.name, type = "DatasetReference" }]
      typeProperties = {
        source = {
          type            = "AzureSqlSource"
          queryTimeout    = "02:00:00"
          partitionOption = "None"
        }
        sink = {
          type                     = "AzureSqlSink"
          writeBehavior            = "insert"
          preCopyScript            = "TRUNCATE TABLE dbo.AR_RECEIVABLES"
          disableMetricsCollection = false
        }
        enableStaging = false
      }
    }
  ])
}
