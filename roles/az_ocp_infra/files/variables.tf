variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
}

variable "az_client_id" {
  description = ""
}

variable "az_subscription_id" {
  description = ""
}

variable "az_tenant_id" {
  description = ""
}

variable "cluster_name" {
  description = "Unique cluster identifier"
}

variable "cluster_location" {
  description = "The region to deploy resources into"
}
variable "cluster_network_name" {
  description = "Name of network to deploy resources into"
}
variable "cluster_subnetwork_name" {
  description = "Name of subnetwork to deploy resources into"
}

variable "rhcos_image_url" {
  description = "URL where RHCOS vhd image is hosted"
}

variable "ignition_dir" {
  description = "Path to ignition files"
}

variable "bootstrap_vm_size" {
  description = "Instance size of bootstrap vm"
}
variable "master_vm_size" {
  description = "Instnace size of master vms"
}
variable "master_vm_count" {
  description = "Number of master hosts to deploy. Must be either 1 or 3"

}
variable "worker_vm_size" {
    description = "Instnace size of worker vms"
}
variable "worker_vm_count" {
  description = "Number of worker hosts to deploy."
}

variable "dns_zone_name" {
  description = "Name of DNS zone"
}