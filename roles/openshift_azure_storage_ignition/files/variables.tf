variable "azure_client_id" {
  description = "Id of service principal used to deploy resources"
}

variable "azure_client_secret" {
  description = "Id of service principal secret used to deploy resources"
}

variable "azure_subscription_id" {
  description = " Id of azure subscription"
}

variable "azure_tenant_id" {
  description = "Id of azure tenant"
}

variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
}

variable "azure_location" {
  description = "The region to deploy resources into"
}

variable "ignition_directory" {
  description = "The directory where ignition files are stored"
}

variable "openshift_cluster_subnet_id" {
  description = "Subnet id that can access cluster storage account and ignition files"
}

variable "openshift_cluster_name" {
  description = "Unique OpenShift cluster identifier"
}