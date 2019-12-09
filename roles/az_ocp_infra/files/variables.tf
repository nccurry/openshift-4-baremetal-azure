variable "azure_resource_group_name" {
  description = "Name of azure resource group to deploy resources into"
  default = "OCP4"
}
variable "cluster_name" {
  description = "Unique cluster identifier"
  default = "ocp3"
}
variable "cluster_location" {
  description = "The region to deploy resources into"
  default = "eastus"
}
variable "cluster_network_name" {
  description = "Name of network to deploy resources into"
  default = "ocp3"
}
variable "cluster_subnetwork_name" {
  description = "Name of subnetwork to deploy resources into"
  default = "ocp3"
}

variable "cluster_identity_id" {
  description = "Service principal id to run cluster resources under"
}
variable "bootstrap_vm_size" {}
variable "master_vm_size" {}
variable "master_vm_count" {}
variable "worker_vm_size" {}
variable "worker_vm_count" {}
variable "admin_user" {}
variable "image_id" {
  default = "RedHat:RHEL:7.7:7.7.2019090316"
  description = "az vm image list --publisher RedHat --all"
}
variable "ssh_key_path" {}
variable "dns_zone_name" {}