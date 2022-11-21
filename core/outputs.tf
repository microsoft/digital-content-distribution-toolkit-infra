# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
  sensitive = true

}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true

}

output "cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  sensitive = true

}

output "cluster_username" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.username
}

output "cluster_password" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.password
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
}

output "identity_resource_id" {
  value = azurerm_user_assigned_identity.pod_identity.id
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.pod_identity.client_id
}


output "instrumentation_key_cms" {
  value     = local.application_insights_instrumentation_key.cms
  sensitive = true
}

output "app_id_cms" {
  value = azurerm_application_insights.application_insights_cms.app_id
}

output "instrumentation_key_oms" {
  value     = local.application_insights_instrumentation_key.oms
  sensitive = true
}

output "app_id_oms" {
  value = azurerm_application_insights.application_insights_oms.app_id
}

output "instrumentation_key_retailer" {
  value     = local.application_insights_instrumentation_key.retailer
  sensitive = true
}

output "app_id_retailer" {
  value = azurerm_application_insights.application_insights_retailer.app_id
}

output "instrumentation_key_user" {
  value     = local.application_insights_instrumentation_key.user
  sensitive = true
}

output "instrumentation_key_incentive" {
  value     = local.application_insights_instrumentation_key.incentive
  sensitive = true
}

output "instrumentation_key_notification" {
  value     = local.application_insights_instrumentation_key.notification
  sensitive = true
}

output "instrumentation_key_device" {
  value     = local.application_insights_instrumentation_key.device
  sensitive = true
}

output "app_id_user" {
  value = azurerm_application_insights.application_insights_user.app_id
}

# Connection strings
output "service_bus_connection_string" {
  value     = local.service_bus_connection_string
  sensitive = true
}

output "redis_cache_connection_string" {
  value     = local.redis_cache_connection_string
  sensitive = true
}

output "cosmos_db_connection_strings" {
  value     = local.cosmos_db_connection_strings
  sensitive = true
}

output "cosmos_db_account_key" {
  value     = local.cosmos_db_account_key
  sensitive = true
}

output "cms_storage_connection_string" {
  value     = local.cms_storage_connection_string
  sensitive = true
}

output "cmscdn_storage_connection_string" {
  value     = local.cmscdn_storage_connection_string
  sensitive = true
}

output "application_gateway_id" {
  value = azurerm_kubernetes_cluster.aks.addon_profile.0.ingress_application_gateway.0.effective_gateway_id
}
