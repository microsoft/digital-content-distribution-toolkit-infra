# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

locals {
  service_bus_connection_string    = azurerm_servicebus_topic_authorization_rule.topic_all_access.primary_connection_string
  service_bus_ses_connection_string    = azurerm_servicebus_topic_authorization_rule.topic_ses_send.primary_connection_string
  service_bus_iotc_connection_string    = azurerm_servicebus_topic_authorization_rule.topic_iotc_send.primary_connection_string
  redis_cache_connection_string    = azurerm_redis_cache.redis.primary_connection_string
  cosmos_db_connection_strings     = azurerm_cosmosdb_account.cosmosdb.connection_strings[0]
  cosmos_db_account_key            = azurerm_cosmosdb_account.cosmosdb.primary_key
  cms_storage_connection_string    = azurerm_storage_account.content_storage_account.primary_connection_string
  cmscdn_storage_connection_string = azurerm_storage_account.contentcdn_storage_account.primary_connection_string

  application_insights_instrumentation_key = {
    cms       = azurerm_application_insights.application_insights_cms.instrumentation_key
    oms       = azurerm_application_insights.application_insights_oms.instrumentation_key
    retailer  = azurerm_application_insights.application_insights_retailer.instrumentation_key
    user      = azurerm_application_insights.application_insights_user.instrumentation_key
    incentive = azurerm_application_insights.application_insights_incentive.instrumentation_key
    notification = azurerm_application_insights.application_insights_notification.instrumentation_key
    device    = azurerm_application_insights.application_insights_device.instrumentation_key 
  }
}
