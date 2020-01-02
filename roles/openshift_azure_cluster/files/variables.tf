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

variable "openshift_cluster_name" {
  description = "Unique OpenShift cluster identifier"
}

variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
}

variable "azure_location" {
  description = "The region to deploy resources into"
}

variable "azure_subnetwork_id" {
  description = "Subnet to deploy instance into"
}

variable "azure_rhcos_image_id" {
  description = "Image id of RHCOS image to use for cluster hosts"
}

variable "bootstrap_ignition_source_uri" {
  description = "Bootstrap ignition URI with associated SAS data. See: https://docs.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string"
}

variable "bootstrap_replicas" {
  description = "How many bootstrap replicas to deploy. Should either be 1 or 0"
}

variable "bootstrap_instance_size" {
  description = "Instance size of bootstrap virtual machine"
}

variable "master_ignition_source_uri" {
  description = "Master ignition URI with associated SAS data. See: https://docs.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string"
}

variable "master_instance_size" {
  description = "Instance size of master virtual machine"
}

variable "worker_ignition_source_uri" {
  description = "Worker ignition URI with associated SAS data. See: https://docs.microsoft.com/en-us/azure/storage/common/storage-configure-connection-string"
}

variable "worker_replicas" {
  description = "How many worker replicas to deploy"
}

variable "worker_instance_size" {
  description = "Instance size of worker virtual machine"
}

variable "azure_dns_zone_resource_group_name" {
  description = "Resource group where cluster dns zone resides"
}

variable "azure_dns_zone_name" {
  description = "Private DNS zone for cluster dns records"
}

variable "tag_cost_center" {
  description = "Cost center tag used for charge back"
}

variable "tag_environment" {
  description = "Environment tag used for organizational queries (e.g. Production, Performance, UAT, QA, Test, Development)"
}

variable "tag_tier" {
  description = "Tier tag used for organizational support queries (e.g. T0, T1, T2, T3, T4)"
}