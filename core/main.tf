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
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = true
    }
  }

  subscription_id = var.subscription_name
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

locals {
  tags = {
    "environment" : var.environment
  }

  kubernetes_version = var.kubernetes_version == "latest" ? null : var.kubernetes_version
}

# resource group
data "azurerm_resource_group" "rg" {
  name = "blendnet-${var.environment}"
}

# ACR
resource "azurerm_container_registry" "acr" {
  name                = "acrblendnet${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Premium"
  
  network_rule_set {
    default_action = "Deny"
    virtual_network {
      action          = "Allow"
      subnet_id       = azurerm_subnet.aks_subnet.id
    }
  }

  tags                = local.tags
  
  lifecycle {
    ignore_changes    = [
      network_rule_set.0.ip_rule,
    ]
  }
}


# Virtual Network

data "azurerm_client_config" "current" {}

locals {
  backend_address_pool_name      = "defaultaddresspool"
  frontend_port_name             = "${azurerm_virtual_network.vnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.vnet.name}-feip"
  http_setting_name              = "defaulthttpsetting"
  listener_name                  = "${azurerm_virtual_network.vnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.vnet.name}-rqrt"
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = var.virtual_network_resource_group
  address_space       = [var.virtual_network_address_prefix]
}

resource "azurerm_subnet" "default" {
  name                                           = "default"
  resource_group_name                            = var.virtual_network_resource_group
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = [var.default_subnet_address_prefix]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks-blendnet-${var.environment}"
  resource_group_name  = var.virtual_network_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_address_prefix]

  service_endpoints = [
    "Microsoft.AzureCosmosDB",
    "Microsoft.ContainerRegistry",
  ]
}

resource "azurerm_subnet" "agw_subnet" {
  name                 = "snet-agw-blendnet-${var.environment}"
  resource_group_name  = var.virtual_network_resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.agw_subnet_address_prefix]
}

# don't manage public ip - AKS creates one
# # Public Ip 
# resource "azurerm_public_ip" "public_ip" {
#   name                = "public-ip-blendnet-${var.environment}"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"

#   tags = local.tags
# }

# don't manage AGW - AKS creates one
# # enableHttp2 false by default
# resource "azurerm_application_gateway" "app_gateway" {
#   name                = "agw-blendnet-${var.environment}"
#   resource_group_name = data.azurerm_resource_group.rg.name
#   location            = data.azurerm_resource_group.rg.location
# lifecycle {
#   ignore_changes = [
#     # Ignore changes to tags, e.g. because a management agent
#     # updates these based on some ruleset managed elsewhere.
#     tags,
#   ]
# }

#   sku {
#     name     = var.agw_sku
#     tier     = var.agw_tier
#     capacity = var.agw_capacity
#   }

#   gateway_ip_configuration {
#     name      = "appGatewayIpConfig"
#     subnet_id = azurerm_subnet.agw_subnet.id
#   }

#   frontend_port {
#     name = local.frontend_port_name
#     port = 80
#   }

#   frontend_ip_configuration {
#     name                 = local.frontend_ip_configuration_name
#     public_ip_address_id = azurerm_public_ip.public_ip.id
#   }

#   backend_address_pool {
#     name = local.backend_address_pool_name
#   }

#   backend_http_settings {
#     name                  = local.http_setting_name
#     cookie_based_affinity = "Disabled"
#     port                  = 80
#     protocol              = "Http"
#     request_timeout       = 30
#   }

#   http_listener {
#     name                           = local.listener_name
#     frontend_ip_configuration_name = local.frontend_ip_configuration_name
#     frontend_port_name             = local.frontend_port_name
#     protocol                       = "Http"
#   }

#   request_routing_rule {
#     name                       = local.request_routing_rule_name
#     rule_type                  = "Basic"
#     http_listener_name         = local.listener_name
#     backend_address_pool_name  = local.backend_address_pool_name
#     backend_http_settings_name = local.http_setting_name
#   }

#   depends_on = [azurerm_virtual_network.vnet, azurerm_public_ip.public_ip]
# }

# resource "azurerm_lb" "lb" {
#   name                = "lb-blendnet-${var.environment}"
#   sku                 = "Standard"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name

#   frontend_ip_configuration {
#     name                 = azurerm_public_ip.public_ip.name
#     public_ip_address_id = azurerm_public_ip.public_ip.id
#   }
# }

# resource "azurerm_private_link_service" "private_link_service" {
#   name                                        = "pvtlnk-svc-blendnet-${var.environment}"
#   location                                    = var.virtual_network_resource_group
#   resource_group_name                         = data.azurerm_resource_group.rg.name
#   load_balancer_frontend_ip_configuration_ids = [azurerm_lb.lb.frontend_ip_configuration.0.id]

#   nat_ip_configuration {
#     name      = azurerm_public_ip.public_ip.name
#     primary   = true
#     subnet_id = azurerm_subnet.default.id
#   }
# }

# resource "azurerm_private_endpoint" "private_link_endpoint" {
#   name                = "pvtlnk-blendnet-${var.environment}"
#   location            = var.virtual_network_resource_group
#   resource_group_name = data.azurerm_resource_group.rg.name
#   subnet_id           = azurerm_subnet.default.id

#   private_service_connection {
#     name                           = "pvtlnk-svc-blendnet-${var.environment}"
#     private_connection_resource_id = azurerm_private_link_service.private_link_service.id
#     is_manual_connection           = true
#   }
# }


# AKS
resource "azurerm_user_assigned_identity" "pod_identity" {
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  name = "blendnet-${var.environment}-pod-identity"
  tags = local.tags
}

resource "azurerm_role_assignment" "pod_identity_role" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.pod_identity.principal_id
  depends_on           = [azurerm_user_assigned_identity.pod_identity]
}

data "azurerm_ssh_public_key" "ssh" {
  name                = "ssh-aks-blendnet-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-blendnet-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "aks-blendnet-${var.environment}-${random_integer.ri.result}"

  default_node_pool {
    name                         = "default"
    only_critical_addons_enabled = true
    node_count                   = var.aks_sys_agent_count
    vm_size                      = var.aks_sys_agent_vm_size
    vnet_subnet_id               = azurerm_subnet.aks_subnet.id
    orchestrator_version         = local.kubernetes_version
    os_sku                       = var.aks_os_sku
  }

  addon_profile {
    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    ingress_application_gateway {
      enabled = true
      # don't manage AGW - AKS creates one automatically
      # gateway_id = azurerm_application_gateway.app_gateway.id
      subnet_id    = azurerm_subnet.agw_subnet.id
      gateway_name = "agw-blendnet-${var.environment}"
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
    }
  }

  # --enable-managed-identity
  # azure will assign the id automatically
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = var.aks_dns_service_ip
    docker_bridge_cidr = var.aks_docker_bridge_cidr
    service_cidr       = var.aks_service_cidr
  }

  role_based_access_control {
    enabled = var.aks_enable_rbac
  }

  linux_profile {
    admin_username = var.vm_user_name

    ssh_key {
      key_data = data.azurerm_ssh_public_key.ssh.public_key
    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]

  tags = local.tags

  lifecycle {
    ignore_changes = [
      api_server_authorized_ip_ranges,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "application_node_pool" {
  name                  = "application"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  orchestrator_version  = local.kubernetes_version
  vm_size               = var.aks_app_agent_vm_size
  vnet_subnet_id        = azurerm_subnet.aks_subnet.id
  node_count            = var.aks_app_agent_count
  os_sku                = var.aks_os_sku

  tags = local.tags
}

# attach ACR to AKS
# add the role to the identity that was assigned to AKS
resource "azurerm_role_assignment" "aks_to_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


locals {
  agw_diagnostic_category_enable = [
    "ApplicationGatewayAccessLog",
    "ApplicationGatewayPerformanceLog",
    "ApplicationGatewayFirewallLog",
  ]
  agw_id = azurerm_kubernetes_cluster.aks.addon_profile.0.ingress_application_gateway.0.effective_gateway_id
}

data "azurerm_monitor_diagnostic_categories" "agw_diagnostic_categories" {
  resource_id = local.agw_id
}

resource "azurerm_monitor_diagnostic_setting" "agw_monitoring_settings" {
  name                           = "agw-diagnostics-settings-blendnet-${var.environment}"
  target_resource_id             = local.agw_id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.agw_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.agw_diagnostic_category_enable, "all") || contains(local.agw_diagnostic_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}


# Content
# TOOD: Add primaryEndpoints and secondaryEndpoints
resource "azurerm_storage_account" "content_storage_account" {
  name                     = "stcontentblendnet${var.environment}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
}

resource "azurerm_storage_account" "contentcdn_storage_account" {
  name                     = "stcontentcdn${var.environment}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  allow_blob_public_access = true
  # primary_blob_endpoint  = "https://stcontentcdn${var.environment}.blob.core.windows.net/"
  tags = local.tags
}

# AMS
resource "azurerm_storage_account" "ams_storage_account" {
  name                     = "storageamsblendnet${var.environment}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
}

# Device storage
resource "azurerm_storage_account" "device_storage_account" {
  name                     = "stblendnetdevices${var.environment}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  tags                     = local.tags
}

# User data export
resource "azurerm_storage_account" "user_data_storage_account" {
  name                     = "stuserdatablendnet${var.environment}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
}

resource "azurerm_media_services_account" "ams" {
  name                = trimspace(tostring(var.ams_account_name))
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  storage_account {
    id         = azurerm_storage_account.ams_storage_account.id
    is_primary = true
  }
  tags = local.tags
}

resource "azurerm_eventgrid_system_topic" "systopic" {
  name                   = "systopic-blendnet-${var.environment}-ams"
  location               = data.azurerm_resource_group.rg.location
  resource_group_name    = data.azurerm_resource_group.rg.name
  source_arm_resource_id = azurerm_media_services_account.ams.id
  topic_type             = "Microsoft.Media.MediaServices"
  tags                   = local.tags
}

resource "azurerm_eventgrid_system_topic_event_subscription" "evtsubscription" {
  name                = "evtsubscription-blendnet-${var.environment}-ams"
  system_topic        = azurerm_eventgrid_system_topic.systopic.name
  resource_group_name = data.azurerm_resource_group.rg.name

  service_bus_topic_endpoint_id = azurerm_servicebus_topic.topic.id

  included_event_types = [
    "Microsoft.Media.JobFinished",
    "Microsoft.Media.JobCanceled",
    "Microsoft.Media.JobErrored"
  ]
}

# already exists
resource "azurerm_media_streaming_endpoint" "streaming_endpoint" {
  name                        = "streaming-endpoint-${var.environment}"
  resource_group_name         = data.azurerm_resource_group.rg.name
  location                    = data.azurerm_resource_group.rg.location
  media_services_account_name = azurerm_media_services_account.ams.name
  scale_units                 = var.ams_streaming_endpoint_scale_units
  cdn_enabled                 = var.ams_streaming_endpoint_cdn_enabled
  tags                        = local.tags
}


# CDN
resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "cdnp-blendnet-${var.environment}"
  location            = "Global"
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
  tags                = local.tags
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "cdn-blendnet-${var.environment}"
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = "Global"
  resource_group_name = data.azurerm_resource_group.rg.name

  origin_host_header = "stcontentcdn${var.environment}.blob.core.windows.net"

  origin {
    name      = "stcontentcdn${var.environment}-blob-core-windows-net"
    host_name = "stcontentcdn${var.environment}.blob.core.windows.net"
  }
  tags = local.tags
}


# application insights
resource "azurerm_application_insights" "application_insights_cms" {
  name                = "appi-blendnet-cms-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled
  
  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}

data "azurerm_monitor_diagnostic_categories" "app_insights_cms_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_cms.id
}

data "azurerm_storage_account" "analytics_storage" {
  name = "nearmestoragaccount" # Change to nearmeanalyticssa, once analytics resources start following naming convention
  resource_group_name = var.analytics_rg_name
}

locals {
  app_insights_cms_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_cms_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_cms.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_cms_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_cms_log_category_enable, "all") || contains(local.app_insights_cms_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_oms" {
  name                = "appi-blendnet-oms-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_oms_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_oms.id
}


locals {
  app_insights_oms_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_oms_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_oms.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_oms_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_oms_log_category_enable, "all") || contains(local.app_insights_oms_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_retailer" {
  name                = "appi-blendnet-retailer-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_retailer_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_retailer.id
}


locals {
  app_insights_retailer_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_retailer_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_retailer.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_retailer_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_retailer_log_category_enable, "all") || contains(local.app_insights_retailer_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_user" {
  name                = "appi-blendnet-user-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_user_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_user.id
}


locals {
  app_insights_user_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_user_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_user.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_user_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_user_log_category_enable, "all") || contains(local.app_insights_user_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_incentive" {
  name                = "appi-blendnet-incentive-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_incentive_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_incentive.id
}


locals {
  app_insights_incentive_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_incentive_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_incentive.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_incentive_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_incentive_log_category_enable, "all") || contains(local.app_insights_incentive_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_notification" {
  name                = "appi-blendnet-notification-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_notification_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_notification.id
}


locals {
  app_insights_notification_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_notification_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_notification.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_notification_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_notification_log_category_enable, "all") || contains(local.app_insights_notification_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


resource "azurerm_application_insights" "application_insights_device" {
  name                = "appi-blendnet-device-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics_workspace.id
  tags                = local.tags

  daily_data_cap_in_gb                  = var.app_insights_daily_data_cap
  daily_data_cap_notifications_disabled = var.app_insights_daily_data_cap_notification_diabled

  lifecycle {
    ignore_changes = [
      tags["DashboardGroup"]
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "app_insights_device_diagnostic_categories" {
  resource_id = azurerm_application_insights.application_insights_device.id
}


locals {
  app_insights_device_log_category_enable = [
    "AppEvents",
    "AppMetrics",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "app_insights_device_monitoring_settings" {
  name                           = "app-insights-export-blendnet-${var.environment}"
  target_resource_id             = azurerm_application_insights.application_insights_device.id
  storage_account_id             = data.azurerm_storage_account.analytics_storage.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.app_insights_device_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.app_insights_device_log_category_enable, "all") || contains(local.app_insights_device_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  
}


# cosmos db
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmos-blendnet-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = data.azurerm_resource_group.rg.location
    failover_priority = 0
  }

  public_network_access_enabled     = true
  is_virtual_network_filter_enabled = true
  virtual_network_rule  {
    id = azurerm_subnet.aks_subnet.id
  }

  backup {
    type = "Continuous"
  }

  ip_range_filter = "104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"

  tags = merge({
    "defaultExperience" : "Core (SQL)",
    "hidden-cosmos-mmspecial" : "",
    "CosmosAccountType" : "Non-Production"
    },
    local.tags
  )

  lifecycle {
    ignore_changes = [
      ip_range_filter,
    ]
  }
}


data "azurerm_monitor_diagnostic_categories" "cosmosdb_diagnostic_categories" {
  resource_id = azurerm_cosmosdb_account.cosmosdb.id
}


locals {
  cosmosdb_log_category_enable = [
    "DataPlaneRequests",
    "QueryRuntimeStatistics",
    "PartitionKeyStatistics",
    "PartitionKeyRUConsumption",
    "ControlPlaneRequests",
  ]
}


resource "azurerm_monitor_diagnostic_setting" "cosmosdb_monitoring_settings" {
  name                           = "cosmos-diagnostics-blendnet-${var.environment}"
  target_resource_id             = azurerm_cosmosdb_account.cosmosdb.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_analytics_workspace.id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.cosmosdb_diagnostic_categories.logs
    content {
      category = log.value
      enabled  = contains(local.cosmosdb_log_category_enable, "all") || contains(local.cosmosdb_log_category_enable, log.value)

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
  metric {
    category = "Requests"

    retention_policy {
      enabled = false
      days    = 0
    }
  }
}


# key vault
resource "azurerm_key_vault" "kv" {
  name                        = "kv-blendnet-${var.environment}"
  location                    = data.azurerm_resource_group.rg.location
  resource_group_name         = data.azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = local.tags
}

resource "azurerm_key_vault_access_policy" "kv-default-access-policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
  ]

  storage_permissions = [
    "Get",
  ]
}

resource "azurerm_key_vault_access_policy" "kv-pod-identity-access-policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.pod_identity.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]
}

# log_analytics
resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = "log-blendnet-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_log_analytics_solution" "log_analytics_solution" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.rg.location
  resource_group_name   = data.azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics_workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics_workspace.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
  tags = local.tags
}

# servicebus
resource "azurerm_servicebus_namespace" "servicebus_namespace" {
  name                = "sb-blendnet-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_servicebus_topic" "topic" {
  name                = "topic-blendnet-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  enable_partitioning = true
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_all_access" {
  name                = "topic-all-access-blendnet-${var.environment}"
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = data.azurerm_resource_group.rg.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_ses_send" {
  name                = "SES-Send"
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = data.azurerm_resource_group.rg.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_servicebus_topic_authorization_rule" "topic_iotc_send" {
  name                = "IOTC-Send"
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = data.azurerm_resource_group.rg.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_servicebus_subscription" "CMSService_subscription" {
  name                = "CMSService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}

resource "azurerm_servicebus_subscription" "RetailerService_subscription" {
  name                = "RetailerService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}

resource "azurerm_servicebus_subscription" "OMSService_subscription" {
  name                = "OMSService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}

resource "azurerm_servicebus_subscription" "IncentiveService_subscription" {
  name                = "IncentiveService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}

resource "azurerm_servicebus_subscription" "DeviceService_subscription" {
  name                = "DeviceService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}

resource "azurerm_servicebus_subscription" "UserService_subscription" {
  name                = "UserService"
  resource_group_name = data.azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebus_namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 10
}


# redis
# NOTE: the Name used for Redis needs to be globally unique
resource "azurerm_redis_cache" "redis" {
  name                = "redis-blendnet-${var.environment}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
  tags = local.tags
}


resource "azurerm_storage_container" "kv_storage_container" {
  name                  = "kv-container-${var.environment}"
  storage_account_name  = "tfstatefor${var.environment}"
  container_access_type = "private"
}

# Key vault values
resource "azurerm_storage_blob" "key_vault_values" {
  name                   = "key_vault_values.json"
  storage_account_name   = "tfstatefor${var.environment}"
  storage_container_name = azurerm_storage_container.kv_storage_container.name
  type                   = "Block"
  content_type           = "text/json"
  source_content         = <<EOT
  {
    "ServiceBusConnectionString": "${local.service_bus_connection_string}",
    "SESServiceBusConnectionString": "${local.service_bus_ses_connection_string}",
    "IOTCServiceBusConnectionString": "${local.service_bus_iotc_connection_string}",
    "RedisCacheConnectionString": "${local.redis_cache_connection_string}",
    "CosmosDbConnectionStrings": "${local.cosmos_db_connection_strings}",
    "CosmosDbAccountKey": "${local.cosmos_db_account_key}",
    "CMSStorageConnectionString": "${local.cms_storage_connection_string}",
    "CMSCDNStorageConnectionString": "${local.cmscdn_storage_connection_string}",
    %{for k, v in local.application_insights_instrumentation_key~}
    "${k}-ApplicationInsights:InstrumentationKey": "${v}", 
    %{endfor~}
  }
  EOT
}


resource "azurerm_container_registry" "iot_acr" {
  name                = "acrbineiot${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard"
  tags                = local.tags
}


resource "azurerm_iotcentral_application" "iotcentral_app" {
  name                = "blendnet-${var.environment}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = "southeastasia"
  sub_domain          = "blendnet-${var.environment}"

  display_name = "blendnet-${var.environment}"
  sku          = "ST2"
  template     = "iotc-pnp-preview@1.0.0"

  tags = local.tags
}
