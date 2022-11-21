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

# Create ssh key for aks 
az sshkey create --name ssh-aks-blendnet-$env --resource-group $RESOURCE_GROUP_NAME --location $region
