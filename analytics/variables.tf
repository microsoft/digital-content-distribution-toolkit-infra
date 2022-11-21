# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

variable "subscription_name" {
  description = "Name of the subscription"
  default     = "75b52ee1-aa3a-477f-87e7-2c2b873ee266"
}

variable "environment" {
  description = "Name of the environment"
  default     = "analytics"
}

variable "location" {
  default = "Central India"
}

variable "rg_name" {
  description = "Resource group name"
  default     = "nearme-analytics"
}

variable "mssql_admin_login_name" {
  description = "SQL server admin login name"
}

variable "mssql_admin_login_password" {
  description = "SQL server admin login password"
}

variable "mssql_max_size_gb" {
  description = "SQL server max size in gb"
  default     = 170
}