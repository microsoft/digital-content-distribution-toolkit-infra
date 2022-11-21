# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

variable "subscription_name" {
  description = "Name of the subscription"
  default     = "75b52ee1-aa3a-477f-87e7-2c2b873ee266"
}

variable "environment" {
  description = "Name of the environment - dev, stage, prod"
  default     = "stage"
}

variable "location" {
  default = "Central India"
}

variable "virtual_network_name" {
  description = "VNET name"
  default     = "vnet-blendnet-stage"
}

variable "virtual_network_resource_group" {
  description = "VNET resource group"
  default     = "blendnet-stage"
}

variable "virtual_network_address_prefix" {
  description = "VNET address prefix"
  default     = "172.20.0.0/16"
}

variable "default_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "172.20.0.0/24"
}

variable "aks_subnet_address_prefix" {
  description = "Subnet address prefix."
  default     = "172.20.64.0/21"
}

variable "agw_subnet_address_prefix" {
  description = "Subnet server IP address."
  default     = "172.20.2.0/24"
}

variable "agw_sku" {
  description = "Name of the Application Gateway SKU"
  default     = "Standard_v2"
}

variable "agw_tier" {
  description = "Tier of the Application Gateway tier"
  default     = "Standard_v2"
}

variable "agw_capacity" {
  description = "Capacity of the Application Gateway"
  default     = 2
}

variable "aks_app_agent_count" {
  description = "The number of agent nodes for the application node cluster."
  default     = 5
}

variable "aks_app_agent_vm_size" {
  description = "application VM size"
  default     = "Standard_D16s_v4"
}

variable "aks_sys_agent_count" {
  description = "The number of agent nodes for the system node cluster."
  default     = 3
}

variable "aks_sys_agent_vm_size" {
  description = "system VM size"
  default     = "Standard_D8s_v4"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  default = "latest"
}

variable "aks_os_sku" {
  description = "AKS OS SKU"
  default     = "CBLMariner"
}

variable "aks_service_cidr" {
  description = "CIDR notation IP range from which to assign service cluster IPs"
  default     = "10.0.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "DNS server IP address"
  default     = "10.0.0.10"
}

variable "aks_docker_bridge_cidr" {
  description = "CIDR notation IP for Docker bridge."
  default     = "172.17.0.1/16"
}

variable "aks_enable_rbac" {
  description = "Enable RBAC on the AKS cluster. Defaults to false."
  default     = "true"
}

variable "vm_user_name" {
  description = "User name for the VM"
  default     = "azureuser"
}

variable "ams_streaming_endpoint_cdn_enabled" {
  description = "ams_streaming_endpoint_cdn_enabled"
  default     = true
}

variable "ams_streaming_endpoint_scale_units" {
  description = "ams_streaming_endpoint_scale_units"
  default     = 3
}

variable "app_insights_daily_data_cap" {
  description = "Application insights daily data cap in GBs"
  default     = 100
}

variable "app_insights_daily_data_cap_notification_diabled" {
  description = "Application insights daily data notification disabled"
  default     = false
}

variable "ams_account_name" {
  description = "Ams account name"
  default     = "amsnearmestage"
}

variable "analytics_rg_name" {
  description = "Analytics resource group name"
  default     = "NearMeAnalyticsPipeline"
}