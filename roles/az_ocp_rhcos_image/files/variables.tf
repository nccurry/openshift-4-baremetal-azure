variable "az_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
}

variable "az_client_id" {
  description = "Id of service principal used to deploy resources"
}

variable "az_subscription_id" {
  description = " Id of azure subscription"
}

variable "az_tenant_id" {
  description = "Id of azure tenant"
}

variable "az_location" {
  description = "The region to deploy resources into"
}

variable "az_rhcos_image_url" {
  description = "URL where RHCOS vhd image is hosted"
}