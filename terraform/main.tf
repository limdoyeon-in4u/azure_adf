resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  prefix = "${var.project}${var.environment}"
  suffix = random_string.suffix.result
  tags = {
    project     = var.project
    environment = var.environment
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.prefix}-${local.suffix}"
  location = var.location
  tags     = local.tags
}
