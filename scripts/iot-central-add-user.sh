# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

# Default values ‘[parameter name]:-[default value]
env=${env:-stage}
userEmail=${userEmail:-}

# Read input param
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

appId=$(az iot central app show -n blendnet-$env --query "applicationId" -o tsv)
userId=$(az ad user show --id $userEmail --query "objectId" -o tsv)

# install iot central application if required
az config set extension.use_dynamic_install=yes_without_prompt

# add user by email
az iot central user create --user-id $userId --app-id $appId --email $userEmail --role admin