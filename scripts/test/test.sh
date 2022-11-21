# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

environment=$1
kubectl apply -f ./pod-id-$environment.yaml
