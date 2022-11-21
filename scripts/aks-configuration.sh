# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

# Default values ‘[parameter name]:-[default value]
environment=${environment:-stage}
subscription=${subscription:-79b6781b-bc04-4e86-95d0-0e81a597feb5}

# Read input param
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done


az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService

# Install the aks-preview extension
az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

az aks get-credentials --resource-group blendnet-$environment --name aks-blendnet-$environment

az aks update -g blendnet-$environment -n aks-blendnet-$environment --enable-pod-identity

az aks pod-identity add --resource-group blendnet-$environment --cluster-name aks-blendnet-$environment --namespace default --name "blendnet-$environment-pod-identity" --identity-resource-id "/subscriptions/$subscription/resourcegroups/blendnet-$environment/providers/Microsoft.ManagedIdentity/userAssignedIdentities/blendnet-$environment-pod-identity"

# kubectl apply -f ./scripts/pod-id-$environment.yaml
