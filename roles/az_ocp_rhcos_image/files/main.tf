terraform {
  backend "local" {}
}

provider "azurerm" {
  client_id = var.az_client_id
  client_secret = var.az_client_secret
  subscription_id = var.az_subscription_id
  tenant_id = var.az_tenant_id
  skip_provider_registration = true
  # Need to comment out for version <1.34.0
  #disable_terraform_partner_id = true
  # Need to pin version due to bug https://github.com/terraform-providers/terraform-provider-azurerm/issues/4361
  version = "<1.34.0"
}

data "azurerm_resource_group" "main" {
  name     = var.az_resource_group_name
}

# Storage

resource "random_string" "storage_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_storage_account" "rhcos" {
  name                     = "openshiftrhcos${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# CoreOS Image

resource "azurerm_storage_container" "vhd" {
  name                 = "vhd"
  storage_account_name = azurerm_storage_account.rhcos.name
}

resource "azurerm_storage_blob" "rhcos_image" {
  name                   = "openshift-rhcos.vhd"
  resource_group_name = data.azurerm_resource_group.main.name
  storage_account_name   = azurerm_storage_account.rhcos.name
  storage_container_name = azurerm_storage_container.vhd.name
  type                   = "block"
  source_uri             = var.az_rhcos_image_url
  metadata               = map("source_uri", var.az_rhcos_image_url)
}

resource "azurerm_image" "rhcos" {
  name                = "openshift-rhcos"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.az_location

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = azurerm_storage_blob.rhcos_image.url
  }
}
