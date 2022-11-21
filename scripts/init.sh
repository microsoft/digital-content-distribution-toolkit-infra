# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash


# Default values ‘[parameter name]:-[default value]
env=${env:-stage}
region=${region:-centralindia}

# Read input param
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

RESOURCE_GROUP_NAME=${rg:-blendnet-$env}
STORAGE_ACCOUNT_NAME=${storageAccName:-tfstatefor$env}
CONTAINER_NAME=tfstate

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $region

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query '[0].value' -o tsv)

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY

echo "$ACCOUNT_KEY"