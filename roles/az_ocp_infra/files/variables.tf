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

variable "az_network_name" {
  description = "Name of network to deploy resources into"
}

variable "az_subnetwork_name" {
  description = "Name of subnetwork to deploy resources into"
}

variable "az_dns_zone_name" {
  description = "Name of DNS zone"
}

variable "az_rhcos_image_id" {
  description = "URL where RHCOS vhd image is hosted"
}

variable "ocp_cluster_name" {
  description = "Unique cluster identifier"
}

variable "ocp_ignition_dir" {
  description = "Path to ignition files"
}

variable "ocp_bootstrap_vm_size" {
  description = "Instance size of bootstrap vm"
}

variable "ocp_master_vm_size" {
  description = "Instnace size of master vms"
}

variable "ocp_master_replicas" {
  description = "Number of master hosts to deploy. Must be either 1 or 3"

}

variable "ocp_worker_vm_size" {
    description = "Instnace size of worker vms"
}

variable "ocp_worker_replicas" {
  description = "Number of worker hosts to deploy."
}

