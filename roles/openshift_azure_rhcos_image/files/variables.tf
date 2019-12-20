variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
}

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

variable "azure_location" {
  description = "The region to deploy resources into"
}

variable "rhcos_image_url" {
  description = "URL where RHCOS vhd image is hosted"
}