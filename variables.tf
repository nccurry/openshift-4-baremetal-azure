variable "cluster_name" {}
variable "cluster_location" {}
variable "cluster_resource_group" {}
variable "cluster_subnet_name" {}
variable "cluster_network_name" {}
variable "cluster_identity_id" {}
variable "master_vm_size" {}
variable "infra_vm_size" {}
variable "worker_vm_size" {}
variable "admin_user" {}
variable "image_id" {
  default = "RedHat:RHEL:7.7:7.7.2019090316"
  description = "az vm image list --publisher RedHat --all"
}
variable "sssh_key_path" {}