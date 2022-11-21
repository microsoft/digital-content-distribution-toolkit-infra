# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

# Default values ‘[parameter name]:-[default value]
env=${env:-stage}

# Read input param
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

appId=$(az iot central app show -n blendnet-$env --query "applicationId" -o tsv)

# install iot central application if required
az config set extension.use_dynamic_install=yes_without_prompt

# generate api token
apiToken=$(az iot central api-token create --token-id "BlendnetCloudApi" --app-id $appId --role operator --query "token" -o tsv)

# add API token in key vault
az keyvault secret set --name iot-central-api-token --vault-name "kv-blendnet-"$env --value "$apiToken"
