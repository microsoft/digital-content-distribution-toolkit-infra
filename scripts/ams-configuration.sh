# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

environment=$1
amsName=$2

az ams account sp create --account-name $amsName --resource-group blendnet-$environment