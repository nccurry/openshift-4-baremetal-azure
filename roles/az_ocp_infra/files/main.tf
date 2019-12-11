terraform {
  backend "local" {}
}

provider "azurerm" {
  client_id = var.az_client_id
  subscription_id = var.az_subscription_id
  tenant_id = var.az_tenant_id
  skip_provider_registration = true
  disable_terraform_partner_id = true
  version = "~>1.38.0"
}

data "azurerm_resource_group" "main" {
  name     = var.az_resource_group_name
}

data azurerm_subnet "main" {
  name = var.az_subnetwork_name
  virtual_network_name = var.az_network_name
  resource_group_name = var.az_resource_group_name
}

data "azurerm_dns_zone" "main" {
  name                = var.az_dns_zone_name
  resource_group_name = data.azurerm_resource_group.main.name
}

# Load Balancers

resource "azurerm_network_security_group" "api-lb" {
  name = "openshift-${var.ocp_cluster_name}-api-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  tags = {}
}

resource "azurerm_network_security_rule" "api-lb-api" {
    name = "openshift-${var.ocp_cluster_name}-api-lb-api"
    resource_group_name = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.api-lb.name
    description = "API traffic from external"
    protocol = "Tcp"
    source_port_range = "6443"
    destination_port_range = "6443"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    access = "Allow"
    priority = "101"
    direction = "Inbound"
}

resource "azurerm_network_security_rule" "api-lb-machine-config" {
    name = "openshift-${var.ocp_cluster_name}-api-lb-machine-config"
    resource_group_name = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.api-lb.name
    description = "MachineConfig traffic from bootstrap / master"
    protocol = "Tcp"
    source_port_range = "22623"
    destination_port_range = "22623"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    access = "Allow"
    priority = "102"
    direction = "Inbound"
}

resource "azurerm_lb" "api-lb" {
  name = "openshift-${var.ocp_cluster_name}-api-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  frontend_ip_configuration {
    name = "openshift-${var.ocp_cluster_name}-api-lb-config"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {}
}

resource "azurerm_lb_backend_address_pool" "api-lb" {
  name = "openshift-${var.ocp_cluster_name}-api-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.api-lb.id
}

resource "azurerm_lb_rule" "api-lb-https" {
  name = "openshift-${var.ocp_cluster_name}-api-lb-https"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  frontend_ip_configuration_name = "openshift-${var.ocp_cluster_name}-api-lb-config"
  protocol = "Tcp"
  frontend_port = "6443"
  backend_port = "6443"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
  probe_id = azurerm_lb_probe.api-lb-https.id
}

resource "azurerm_lb_probe" "api-lb-https" {
  name = "openshift-${var.ocp_cluster_name}-api-lb-https"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  protocol = "Tcp"
  port = "6443"
}

resource "azurerm_lb_rule" "api-lb-machine-config" {
  name = "openshift-${var.ocp_cluster_name}-api-lb-machine-config"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  frontend_ip_configuration_name = "openshift-${var.ocp_cluster_name}-api-lb-config"
  protocol = "Tcp"
  frontend_port = "22623"
  backend_port = "22623"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
  probe_id = azurerm_lb_probe.api-lb-machine-config.id
}

resource "azurerm_lb_probe" "api-lb-machine-config" {
  name = "openshift-${var.ocp_cluster_name}-api-lb-machine-config"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  protocol = "Tcp"
  port = "22623"
}

resource "azurerm_network_security_group" "ingress-lb" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  tags = {}
}

resource "azurerm_network_security_rule" "ingress-lb-http" {
    name = "openshift-${var.ocp_cluster_name}-ingress-lb-http"
    resource_group_name = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.ingress-lb.name
    description = "Ingress http from external"
    protocol = "Tcp"
    source_port_range = "80"
    destination_port_range = "80"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    access = "Allow"
    priority = "101"
    direction = "Inbound"
}

resource "azurerm_network_security_rule" "ingress-lb-https" {
    name = "openshift-${var.ocp_cluster_name}-ingress-lb-https"
    resource_group_name = data.azurerm_resource_group.main.name
    network_security_group_name = azurerm_network_security_group.ingress-lb.name
    description = "Ingress http from external"
    protocol = "Tcp"
    source_port_range = "443"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    access = "Allow"
    priority = "102"
    direction = "Inbound"
}

resource "azurerm_lb" "ingress-lb" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  frontend_ip_configuration {
    name = "openshift-${var.ocp_cluster_name}-ingress-lb-config"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {}
}

resource "azurerm_lb_backend_address_pool" "ingress-lb" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.ingress-lb.id
}

resource "azurerm_lb_rule" "ingress-lb-https" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb-https"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  frontend_ip_configuration_name = "openshift-${var.ocp_cluster_name}-ingress-lb-config"
  protocol = "Tcp"
  frontend_port = "443"
  backend_port = "443"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id = azurerm_lb_probe.ingress-lb-http.id
}

resource "azurerm_lb_rule" "ingress-lb-http" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb-http"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  frontend_ip_configuration_name = "openshift-${var.ocp_cluster_name}-ingress-lb-config"
  protocol = "Tcp"
  frontend_port = "80"
  backend_port = "80"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id = azurerm_lb_probe.ingress-lb-http.id
}

resource "azurerm_lb_probe" "ingress-lb-http" {
  name = "openshift-${var.ocp_cluster_name}-ingress-lb-http"
  resource_group_name = data.azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  protocol = "Tcp"
  port = "80"
}

# Storage

resource "azurerm_storage_account" "cluster" {
  name                     = "openshiftignition${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = var.az_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Bootstrap

resource "random_string" "storage_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_storage_container" "ignition" {
  name                  = "ignition"
  storage_account_name  = azurerm_storage_account.cluster.name
  container_access_type = "private"
}

resource "azurerm_network_security_group" "bootstrap" {
  name = "openshift-${var.ocp_cluster_name}-bootstrap"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  tags = {}
}

resource "azurerm_network_security_rule" "bootstrap-ssh" {
  name = "openshift-${var.ocp_cluster_name}-bootstrap-ssh"
  resource_group_name = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.bootstrap.name
  description = "SSH traffic from external"
  protocol = "Tcp"
  source_port_range = "22"
  destination_port_range = "22"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  access = "Allow"
  priority = "100"
  direction = "Inbound"
}

data "azurerm_storage_account_sas" "ignition" {
  connection_string = azurerm_storage_account.cluster.primary_connection_string
  https_only        = true

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "24h")

  permissions {
    read    = true
    list    = true
    create  = false
    add     = false
    delete  = false
    process = false
    write   = false
    update  = false
  }
}

resource "azurerm_storage_blob" "ignition" {
  name                   = "bootstrap.ign"
  source                 = "${var.ocp_ignition_dir}/bootstrap.ign"
  storage_account_name   = azurerm_storage_account.cluster.name
  storage_container_name = azurerm_storage_container.ignition.name
  type                   = "block"
}

data "ignition_config" "bootstrap-redirect" {
  replace {
    source = "${azurerm_storage_blob.ignition.url}${data.azurerm_storage_account_sas.ignition.sas}"
  }
}

resource "azurerm_network_interface" "bootstrap" {
  name = "openshift-${var.ocp_cluster_name}-bootstrap-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_security_group_id = azurerm_network_security_group.bootstrap.id
  ip_configuration {
    name = "openshift-${var.ocp_cluster_name}-bootstrap-nic-config"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "bootstrap" {
  network_interface_id    = azurerm_network_interface.bootstrap.id
  ip_configuration_name   = "openshift-${var.ocp_cluster_name}-bootstrap-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
}

resource "azurerm_virtual_machine" "bootstrap" {
  depends_on = [
    azurerm_storage_blob.ignition
  ]
  name = "openshift-${var.ocp_cluster_name}-bootstrap"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_interface_ids = [
    azurerm_network_interface.bootstrap.id
  ]
  os_profile_linux_config {
    disable_password_authentication = false
  }
  vm_size = var.ocp_bootstrap_vm_size
  availability_set_id = azurerm_availability_set.master.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  os_profile {
    computer_name = "openshift-${var.ocp_cluster_name}-bootstrap"
    admin_username = "core"
    admin_password = "NotActuallyApplied!"
    custom_data    = data.ignition_config.bootstrap-redirect.rendered
  }
  storage_os_disk {
    name = "openshift-${var.ocp_cluster_name}-bootstrap-disk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 100
//    managed_disk_id = azurerm_managed_disk.bootstrap.id
//    os_type = "Linux"
  }
  storage_image_reference {
    id = var.az_rhcos_image_id
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.cluster.primary_blob_endpoint
  }
  tags = {}
}

# Master

resource "azurerm_network_security_group" "master" {
  name = "openshift-${var.ocp_cluster_name}-master"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  tags = {}
}

resource "azurerm_network_security_rule" "master-ssh" {
  name = "openshift-${var.ocp_cluster_name}-master-ssh"
  resource_group_name = data.azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.master.name
  description = "SSH traffic from external"
  protocol = "Tcp"
  source_port_range = "22"
  destination_port_range = "22"
  source_address_prefix = "*"
  destination_address_prefix = "*"
  access = "Allow"
  priority = "100"
  direction = "Inbound"
}

resource "azurerm_availability_set" "master" {
  name                = "openshift-${var.ocp_cluster_name}-master"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  managed = true
  tags = {}
}

resource "azurerm_network_interface" "master" {
  count = 3
  name = "openshift-${var.ocp_cluster_name}-master-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_security_group_id = azurerm_network_security_group.master.id
  ip_configuration {
    name = "openshift-${var.ocp_cluster_name}-master-nic-config"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count = 3
  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  ip_configuration_name   = "openshift-${var.ocp_cluster_name}-master-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
}

resource "azurerm_virtual_machine" "master" {
  depends_on = [
    azurerm_virtual_machine.bootstrap
  ]
  count = 3
  name = "openshift-${var.ocp_cluster_name}-master-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_interface_ids = [
    element(azurerm_network_interface.master.*.id, count.index)
  ]
  os_profile_linux_config {
    disable_password_authentication = false
  }
  vm_size = var.ocp_master_vm_size
  availability_set_id = azurerm_availability_set.master.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  os_profile {
    computer_name = "openshift-${var.ocp_cluster_name}-master-${count.index}"
    admin_username = "core"
    admin_password = "NotActuallyApplied!"
    custom_data    = file("${var.ocp_ignition_dir}/master.ign")
  }
  storage_os_disk {
    name = "openshift-${var.ocp_cluster_name}-master-${count.index}-disk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 200
//    managed_disk_id = element(azurerm_managed_disk.master.*.id, count.index)
//    os_type = "Linux"
  }
  storage_image_reference {
    id = var.az_rhcos_image_id
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.cluster.primary_blob_endpoint
  }
  tags = {}
}

# Worker

resource "azurerm_network_security_group" "worker" {
  name = "openshift-${var.ocp_cluster_name}-worker"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  tags = {}
}

resource "azurerm_availability_set" "worker" {
  name                = "openshift-${var.ocp_cluster_name}-worker"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  managed = true
  tags = {}
}

resource "azurerm_network_interface" "worker" {
  count = var.ocp_worker_replicas
  name = "openshift-${var.ocp_cluster_name}-worker-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_security_group_id = azurerm_network_security_group.worker.id
  ip_configuration {
    name = "openshift-${var.ocp_cluster_name}-worker-nic-config"
    subnet_id = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "worker" {
  depends_on = [
    azurerm_virtual_machine.master
  ]
  count = var.ocp_worker_replicas
  name = "openshift-${var.ocp_cluster_name}-worker-${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location = var.az_location
  network_interface_ids = [
    element(azurerm_network_interface.worker.*.id, count.index)
  ]
  os_profile_linux_config {
    disable_password_authentication = false
  }
  vm_size = var.ocp_worker_vm_size
  availability_set_id = azurerm_availability_set.worker.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  os_profile {
    computer_name = "openshift-${var.ocp_cluster_name}-worker-${count.index}"
    admin_username = "core"
    admin_password = "NotActuallyApplied!"
    custom_data    = file("${var.ocp_ignition_dir}/worker.ign")
  }
  storage_os_disk {
    name = "openshift-${var.ocp_cluster_name}-worker-${count.index}-disk"
    caching           = "ReadOnly"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 200
//    managed_disk_id = element(azurerm_managed_disk.worker.*.id, count.index)
//    os_type = "Linux"
  }
  storage_image_reference {
    id = var.az_rhcos_image_id
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.cluster.primary_blob_endpoint
  }
  tags = {}
}

# DNS Entries

resource "azurerm_dns_a_record" "api-public" {
  name = "api.${var.ocp_cluster_name}"
  resource_group_name = var.az_resource_group_name
  zone_name = data.azurerm_dns_zone.main.name
  ttl = 300
  records = [
    azurerm_lb.api-lb.private_ip_address
  ]
  tags = {}
}

resource "azurerm_dns_a_record" "api-private" {
  name = "api-int.${var.ocp_cluster_name}"
  resource_group_name = var.az_resource_group_name
  zone_name = data.azurerm_dns_zone.main.name
  ttl = 300
  records = [
    azurerm_lb.api-lb.private_ip_address
  ]
  tags = {}
}

resource "azurerm_dns_a_record" "ingress" {
  name = "*.apps.${var.ocp_cluster_name}"
  resource_group_name = var.az_resource_group_name
  zone_name = data.azurerm_dns_zone.main.name
  ttl = 300
  records = [
    azurerm_lb.ingress-lb.private_ip_address
  ]
  tags = {}
}

resource "azurerm_dns_a_record" "etcd" {
  count = 3
  name = "etcd-${count.index}.${var.ocp_cluster_name}"
  resource_group_name = var.az_resource_group_name
  zone_name = data.azurerm_dns_zone.main.name
  ttl = 300
  records = [
    element(azurerm_network_interface.master.*.private_ip_address, count.index)
  ]
}

resource "azurerm_dns_srv_record" "etcd" {
  name = "_etcd-server-ssl._tcp.${var.ocp_cluster_name}"
  resource_group_name = var.az_resource_group_name
  zone_name = data.azurerm_dns_zone.main.name
  ttl = 300
  record {
    port = 2380
    priority = 0
    target = element(azurerm_dns_a_record.etcd.*.fqdn, 0)
    weight = 10
  }
  record {
    port = 2380
    priority = 0
    target = element(azurerm_dns_a_record.etcd.*.fqdn, 1)
    weight = 10
  }
    record {
    port = 2380
    priority = 0
    target = element(azurerm_dns_a_record.etcd.*.fqdn, 2)
    weight = 10
  }
}