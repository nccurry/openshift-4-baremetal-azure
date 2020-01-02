terraform {
  backend "azurerm" {
    key = "openshift_azure_rhcos_image"
  }
}

provider "azurerm" {
  client_id = var.azure_client_id
  client_secret = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id = var.azure_tenant_id
  skip_provider_registration = true
  # Need to comment out for version <1.34.0
  #disable_terraform_partner_id = true
  # Need to pin version due to bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/4361
  # Probably fixed in >1.40.0
  version = "<1.34.0"
}

module "openshift_azure_rhcos_image" {
  source = "git::https://github.com/nccurry/openshift-4-terraform-modules//openshift_azure_rhcos_image"
  azure_resource_group_name = var.azure_resource_group_name
  azure_location = var.azure_location
  rhcos_image_url = var.rhcos_image_url
  tag_cost_center = var.tag_cost_center
  tag_environment = var.tag_environment
  tag_tier = var.tag_tier
}