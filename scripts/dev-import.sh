# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

SUBSCRIPTION_NAME=$1
ENVIRONMENT="dev"

terraform import azurerm_virtual_network.vnet /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/virtualNetworks/vnet-blendnet-$ENVIRONMENT

terraform import azurerm_subnet.default /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/virtualNetworks/vnet-blendnet-$ENVIRONMENT/subnets/default

terraform import azurerm_subnet.aks_subnet /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/virtualNetworks/vnet-blendnet-$ENVIRONMENT/subnets/snet-aks-blendnet-$ENVIRONMENT

terraform import azurerm_subnet.agw_subnet /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/virtualNetworks/vnet-blendnet-$ENVIRONMENT/subnets/snet-agw-blendnet-$ENVIRONMENT

terraform import azurerm_kubernetes_cluster.aks /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.ContainerService/managedClusters/aks-blendnet-$ENVIRONMENT

terraform import azurerm_container_registry.acr /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.ContainerRegistry/registries/acrblendnet$ENVIRONMENT

terraform import azurerm_application_gateway.app_gateway /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/applicationGateways/agw-blendnet-$ENVIRONMENT

terraform import azurerm_user_assigned_identity.pod_identity /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.ManagedIdentity/userAssignedIdentities/blendnet-$ENVIRONMENT-pod-identity

terraform import azurerm_media_services_account.ams /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Media/mediaservices/amsblendnet$ENVIRONMENT

terraform import azurerm_storage_account.ams_storage_account /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Storage/storageAccounts/stblendnetams$ENVIRONMENT

terraform import azurerm_application_insights.application_insights_cms /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/microsoft.insights/components/appi-blendnet-cms-$ENVIRONMENT

terraform import azurerm_application_insights.application_insights_oms /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/microsoft.insights/components/appi-blendnet-oms-$ENVIRONMENT

terraform import azurerm_application_insights.application_insights_retailer /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/microsoft.insights/components/appi-blendnet-retailer-$ENVIRONMENT

terraform import azurerm_cosmosdb_account.cosmosdb /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-blendnet-$ENVIRONMENT

terraform import azurerm_key_vault.kv /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.KeyVault/vaults/kv-blendnet-$ENVIRONMENT

terraform import azurerm_servicebus_namespace.servicebus_namespace /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.ServiceBus/namespaces/sb-blendnet-$ENVIRONMENT

terraform import azurerm_servicebus_topic.topic /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.ServiceBus/namespaces/sb-blendnet-$ENVIRONMENT/topics/topic-blendnet-$ENVIRONMENT

terraform import azurerm_log_analytics_workspace.log_analytics_workspace /subscriptions/$SUBSCRIPTION_NAME/resourcegroups/blendnet-$ENVIRONMENT/providers/microsoft.operationalinsights/workspaces/log-blendnet-$ENVIRONMENT

terraform import azurerm_storage_account.content_storage_account /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Storage/storageAccounts/stblendnetcontent$ENVIRONMENT

terraform import azurerm_storage_account.contentcdn_storage_account /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Storage/storageAccounts/stblendnetcdncontent$ENVIRONMENT

# terraform import azurerm_private_endpoint.private_link_endpoint /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Network/privateEndpoints/pvtlnk-blendnet-$ENVIRONMENT

terraform import azurerm_media_streaming_endpoint.streaming_endpoint /subscriptions/$SUBSCRIPTION_NAME/resourceGroups/blendnet-$ENVIRONMENT/providers/Microsoft.Media/mediaservices/amsblendnet$ENVIRONMENT/streamingendpoints/default
