# Dataset - Staging (Data Flow 소스)
resource "azurerm_data_factory_custom_dataset" "ds_staging" {
  name            = "ds_ar_staging"
  data_factory_id = azurerm_data_factory.adf.id
  type            = "AzureSqlTable"

  linked_service {
    name = azurerm_data_factory_linked_service_azure_sql_database.ls_sql.name
  }

  type_properties_json = jsonencode({
    tableName = "dbo.AR_RECEIVABLES_STAGING"
  })
}

# Data Flow - 미수금액/미수일수/미수상태 재계산
resource "azurerm_data_factory_data_flow" "df_ar" {
  name            = "df_transform_ar"
  data_factory_id = azurerm_data_factory.adf.id

  source {
    name = "SourceStaging"
    dataset {
      name = azurerm_data_factory_custom_dataset.ds_staging.name
    }
    linked_service {
      name = azurerm_data_factory_linked_service_azure_sql_database.ls_sql.name
    }
  }

  sink {
    name = "SinkAR"
    dataset {
      name = azurerm_data_factory_custom_dataset.ds_sql.name
    }
    linked_service {
      name = azurerm_data_factory_linked_service_azure_sql_database.ls_sql.name
    }
  }

  script = <<-EOT
    source(output(
            거래처코드 as string,
            거래처명 as string,
            청구번호 as string,
            청구일자 as date,
            만기일자 as date,
            통화 as string,
            청구금액 as long,
            수금금액 as long,
            담당자 as string,
            담당부서 as string,
            비고 as string
        ),
        allowSchemaDrift: true,
        validateSchema: false,
        isolationLevel: 'READ_UNCOMMITTED',
        format: 'table') ~> SourceStaging
    SourceStaging derive(
            미수금액 = 청구금액 - 수금금액,
            미수일수 = toInteger(iif(daysBetween(만기일자, currentDate()) > 0, daysBetween(만기일자, currentDate()), 0L)),
            미수상태 = case(
                iif(daysBetween(만기일자, currentDate()) > 0, daysBetween(만기일자, currentDate()), 0L) == 0L, '정상',
                iif(daysBetween(만기일자, currentDate()) > 0, daysBetween(만기일자, currentDate()), 0L) <= 30L, '주의',
                iif(daysBetween(만기일자, currentDate()) > 0, daysBetween(만기일자, currentDate()), 0L) <= 90L, '연체',
                '위험')) ~> DeriveMetrics
    DeriveMetrics sink(allowSchemaDrift: true,
        validateSchema: false,
        deletable: false,
        insertable: true,
        updateable: false,
        upsertable: false,
        truncate: true,
        format: 'table',
        skipDuplicateMapInputs: true,
        skipDuplicateMapOutputs: true) ~> SinkAR
  EOT
}

# Dataset - Transform View (2차 Copy 소스)
resource "azurerm_data_factory_custom_dataset" "ds_view" {
  name            = "ds_ar_view"
  data_factory_id = azurerm_data_factory.adf.id
  type            = "AzureSqlTable"

  linked_service {
    name = azurerm_data_factory_linked_service_azure_sql_database.ls_sql.name
  }

  type_properties_json = jsonencode({
    tableName = "dbo.vw_ar_transform"
  })
}

# Schedule Trigger - 매일 02:00 KST (= 17:00 UTC)
resource "azurerm_data_factory_trigger_schedule" "daily" {
  name            = "trigger_daily_ar"
  data_factory_id = azurerm_data_factory.adf.id
  pipeline_name   = azurerm_data_factory_pipeline.pipeline_copy.name

  frequency  = "Day"
  interval   = 1
  start_time = "2026-06-25T17:00:00Z"
  time_zone  = "Korea Standard Time"
}
