# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_name
}

locals {
  tags = {
    "environment" : var.environment
  }
}


# Resource group
data "azurerm_resource_group" "rg" {
  name = var.rg_name
}

# Storage
resource "azurerm_storage_account" "analytics_default_storage_account" {
  name                     = "nearme${var.environment}sa"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
}

resource "azurerm_storage_account" "analytics_functionapp_storage_account" {
  name                     = "nearme${var.environment}aspsa"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}


# Database
resource "azurerm_mssql_server" "analytics_sql_server" {
  name                         = "nearme-${var.environment}-sqlserver"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.mssql_admin_login_name
  administrator_login_password = var.mssql_admin_login_password
  tags                         = local.tags
}


resource "azurerm_mssql_database" "analytics_sql_database" {
  name           = "nearme-${var.environment}-sqldb"
  server_id      = azurerm_mssql_server.analytics_sql_server.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.mssql_max_size_gb
  read_scale     = false
  sku_name       = "GP_Gen5_2"
  zone_redundant = false

  tags           = local.tags
}

# ADF
resource "azurerm_data_factory" "analytics_adf" {
  name                         = "nearme-${var.environment}-data-factory"
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location

  # ADO Config
  vsts_configuration {
    account_name               = "binemsr"
    branch_name                = "adf_collaborate"
    project_name               = "Dashboard"
    repository_name            = "Dashboard"
    root_folder                = "/ADF"
    tenant_id                  = "72f988bf-86f1-41af-91ab-2d7cd011db47"
  }

  identity {
    type                       = "SystemAssigned"
  }

  tags                         = local.tags
}


# Azure functions
resource "azurerm_app_service_plan" "analytics_asp" {
  name                = "nearme-${var.environment}-functions-service-plan"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }

  tags                 = local.tags
}

resource "azurerm_function_app" "analytics_azure_function" {
  name                       = "nearme-${var.environment}-azure-functions"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  app_service_plan_id        = azurerm_app_service_plan.analytics_asp.id
  storage_account_name       = azurerm_storage_account.analytics_functionapp_storage_account.name
  storage_account_access_key = azurerm_storage_account.analytics_functionapp_storage_account.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  tags                       = local.tags
}
