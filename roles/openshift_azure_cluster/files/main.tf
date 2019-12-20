terraform {
  backend "azurerm" {
    key = "openshift_azure_bootstrap"
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

module "openshift_azure_cluster" {
  source = "git::https://github.com/nccurry/openshift-4-terraform-modules//openshift_azure_cluster"
  openshift_cluster_name = var.openshift_cluster_name
  azure_resource_group_name = var.azure_resource_group_name
  azure_location = var.azure_location
  azure_subnetwork_id = var.azure_subnetwork_id
  azure_rhcos_image_id = var.azure_rhcos_image_id
  bootstrap_ignition_source_uri = var.bootstrap_ignition_source_uri
  bootstrap_replicas = var.bootstrap_replicas
  bootstrap_instance_size = var.bootstrap_instance_size
  master_ignition_source_uri = var.master_ignition_source_uri
  master_instance_size = var.master_instance_size
  worker_ignition_source_uri = var.worker_ignition_source_uri
  worker_replicas = var.worker_replicas
  worker_instance_size = var.worker_instance_size
  azure_dns_zone_resource_group_name = var.azure_dns_zone_resource_group_name
  azure_dns_zone_name = var.azure_dns_zone_name
}