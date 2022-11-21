# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#!/bin/bash

# Read input param
while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi

  shift
done

# Last monday, the day ips are updated
last_mon=`date "+%C%y%m%d" -d "last mon"`

# Default values ‘[parameter name]:-[default value]
env=${env:-stage}
RESOURCE_GROUP_NAME=${rg:-blendnet-$env}
date=${date:-$last_mon}
AKS_CLUSTER_NAME=aks-blendnet-$env
ACR_NAME="acrblendnet$env"


IPS_FILENAME="ips.json"
FILE_BASE_URL="https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/"

exec 3>&1
log ()
{
    echo -e "Log [INFO]: $1 \n" 1>&3
}


get_file_url() {
    filename="ServiceTags_Public_$date.json"
    echo $FILE_BASE_URL$filename
}


download_ip_json() {
    file_url=$(get_file_url)
    
    log "Downloading file with url: $file_url"
    status_code=$(curl --write-out '%{http_code}' -sL $file_url -o $IPS_FILENAME)

    if [[ "$status_code" -ne 200 ]] ; 
    then
        echo "Error downloading file with url: $file_url " 
        echo "returned status $status_code"
        exit 1
    fi
}


parse_ips_aks() {
    
    log "Extracting ips from the downloaded json for aks."
    ips=`cat $IPS_FILENAME | jq '[.values[] | select(.id==("AzureCloud.centralindia", "AzureCloud.southindia", "AzureCloud.westindia")) | .properties.addressPrefixes | .[]] |  map(select(. | contains(":") | not)) | join(",")'`
    echo $ips
}


parse_ips_acr() {
    
    log "Extracting ips from the downloaded json for acr."
    ips=`cat $IPS_FILENAME | jq '[.values[] | select(.id==("AzureCloud.southindia", "AzureCloud.centralindia")) | .properties.addressPrefixes | .[]] |  map(select(. | contains(":") | not)) | join(",")'`
    echo $ips
}


log "Getting Azure DevOps IP adresses."
# Download the ip json file
download_ip_json

# Get ips for aks and remove double quotes
authorized_ips_aks=`parse_ips_aks | tr -d \"`
log "Found ips for aks: $authorized_ips_aks"

log "Updating Azure DevOps IP addresses in $AKS_CLUSTER_NAME ."
az aks update --resource-group $RESOURCE_GROUP_NAME  --name $AKS_CLUSTER_NAME  --api-server-authorized-ip-ranges $authorized_ips_aks


# az acr update --name $ACR_NAME --default-action Deny
log "Getting existing ips."
acr_exiting_ips=`az acr network-rule list --name $ACR_NAME | jq '.ipRules[].ipAddressOrRange'`

log "Remove existing ips."
for ip in $acr_exiting_ips ; do 
    log "Removing ip: $ip"
    ip=`echo $ip | tr -d \"`
    az acr network-rule remove --name $ACR_NAME -g $RESOURCE_GROUP_NAME --ip-address $ip
done


authorized_ips_acr=`parse_ips_acr | tr -d \"`
log "Found ips for acr: $authorized_ips_acr"

log "Updating Azure DevOps IP addresses in $ACR_NAME ."
for ip in ${authorized_ips_acr//,/ } ; do 
    az acr network-rule add --name $ACR_NAME --ip-address $ip
done
