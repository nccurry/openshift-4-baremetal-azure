terraform {
  backend "azurerm" {
    key = "openshift_azure_storage_ignition"
  }
}

provider "azurerm" {
  client_id = var.azure_client_id
  client_secret = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id = var.azure_tenant_id
  skip_provider_registration = true
  disable_terraform_partner_id = true
  version = "~>1.39.0"
}

module "openshift_azure_storage_ignition" {
  source = "git::https://github.com/nccurry/openshift-4-terraform-modules//openshift_azure_storage_ignition"
  azure_resource_group_name = var.azure_resource_group_name
  azure_location = var.azure_location
  ignition_directory = var.ignition_directory
  openshift_cluster_name = var.openshift_cluster_name
}