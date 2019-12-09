variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
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

variable "bootstrap_vm_size" {}
variable "master_vm_size" {}
variable "master_vm_count" {}
variable "worker_vm_size" {}
variable "worker_vm_count" {}
variable "ssh_key_data" {
  description = "Contents of public ssh key used to access cluster hosts"
}
variable "dns_zone_name" {}