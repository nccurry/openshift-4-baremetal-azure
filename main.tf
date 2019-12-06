provider "azurerm" {
  subscription_id = var.azure_subscription_id
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
}

resource "azurerm_resource_group" "main" {
  name     = var.cluster_resource_group
  location = var.cluster_location
}

data azurerm_subnet "cluster" {
  name = var.cluster_subnet_name
  virtual_network_name = var.cluster_network_name
  resource_group_name = var.cluster_resource_group
}

# Load Balancers

# https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "api-lb" {
  name = "openshift-${var.cluster_name}-api-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-api-lb-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "API traffic from external"
    protocol = "Tcp"
    source_port_range = "6443"
    destination_port_range = "6443"
    source_address_prefix = "*"
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-api-lb-machine-config"
    resource_group_name = azurerm_resource_group.main.name
    description = "MachineConfig traffic from bootstrap / master"
    protocol = "Tcp"
    source_port_range = "22623"
    destination_port_range = "22623"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/loadbalancer.html
resource "azurerm_lb" "api-lb" {
  name = "openshift-${var.cluster_name}-api-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  frontend_ip_configuration {
    name = "openshift-${var.cluster_name}-api-lb-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/loadbalancer_backend_address_pool.html
resource "azurerm_lb_backend_address_pool" "api-lb" {
  name = "openshift-${var.cluster_name}-api-lb"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.api-lb.id
}

# https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "ingress-lb" {
  name = "openshift-${var.cluster_name}-ingress-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-ingress-lb-http"
    resource_group_name = azurerm_resource_group.main.name
    description = "Ingress http from external"
    protocol = "Tcp"
    source_port_range = "80"
    destination_port_range = "80"
    source_address_prefix = "*"
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-ingress-lb-https"
    resource_group_name = azurerm_resource_group.main.name
    description = "Ingress http from external"
    protocol = "Tcp"
    source_port_range = "443"
    destination_port_range = "443"
    source_address_prefix = "*"
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/loadbalancer.html
resource "azurerm_lb" "ingress-lb" {
  name = "openshift-${var.cluster_name}-ingress-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  frontend_ip_configuration {
    name = "openshift-${var.cluster_name}-ingress-lb-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/loadbalancer_backend_address_pool.html
resource "azurerm_lb_backend_address_pool" "ingress-lb" {
  name = "openshift-${var.cluster_name}-ingress-lb"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.ingress-lb.id
}

# Bootstrap

# https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "bootstrap" {
  name = "openshift-${var.cluster_name}-bootstrap"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-ssh"
    resource_group_name = azurerm_resource_group.main.name
    description = "SSH traffic from external"
    protocol = "Tcp"
    source_port_range = "22"
    destination_port_range = "22"
    source_address_prefix = "*"
    access = "Allow"
    priority = "100"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-etcd"
    resource_group_name = azurerm_resource_group.main.name
    description = "Etcd traffic from master hosts"
    protocol = "Tcp"
    source_port_range = "2379-2380"
    destination_port_range = "2379-2380"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "Api traffic from master hosts and load balancer"
    protocol = "Tcp"
    source_port_range = "6443"
    destination_port_range = "6443"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.api-lb.id
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-host-services-tcp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from master hosts"
    protocol = "Tcp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-kubernetes"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubernetes traffic from master hosts"
    protocol = "Tcp"
    source_port_range = "10249-10259"
    destination_port_range = "10249-10259"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-vxlan-geneve-1"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from master hosts"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "105"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-vxlan-geneve-2"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from master hosts"
    protocol = "Udp"
    source_port_range = "6081"
    destination_port_range = "6081"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "106"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-host-services-udp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from master hosts"
    protocol = "Udp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "107"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-bootstrap-machine-config"
    resource_group_name = azurerm_resource_group.main.name
    description = "MachineConfig from load balancer"
    protocol = "Tcp"
    source_port_range = "22623"
    destination_port_range = "22623"
    source_application_security_group_ids = [
      azurerm_network_security_group.api-lb.id
    ]
    access = "Allow"
    priority = "108"
    direction = "Inbound"
  }

  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface.html
resource "azurerm_network_interface" "bootstrap" {
  name = "openshift-${var.cluster_name}-bootstrap-nic"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_security_group_id = azurerm_network_security_group.bootstrap.id
  ip_configuration {
    name = "openshift-${var.cluster_name}-bootstrap-nic-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface_backend_address_pool_association.html
resource "azurerm_network_interface_backend_address_pool_association" "bootstrap" {
  network_interface_id    = azurerm_network_interface.bootstrap.id
  ip_configuration_name   = "openshift-${var.cluster_name}-bootstrap-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
}

# https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html
resource "azurerm_virtual_machine" "bootstrap" {
  name = "openshift-${var.cluster_name}-bootstrap"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_interface_ids = [
    azurerm_network_interface.bootstrap.id
  ]
  vm_size = var.bootstrap_vm_size
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  identity {
    type = "UserAssigned "
    identity_ids = []
  }
}








# https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "master" {
  name = "openshift-${var.cluster_name}-master"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-master-etcd"
    resource_group_name = azurerm_resource_group.main.name
    description = "Etcd traffic from bootstrap/master hosts"
    protocol = "Tcp"
    source_port_range = "2379-2380"
    destination_port_range = "2379-2380"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "Api traffic from cluster hosts and load balancer"
    protocol = "Tcp"
    source_port_range = "6443"
    destination_port_range = "6443"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id,
      azurerm_network_security_group.api-lb.id
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-host-services-tcp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from cluster hosts"
    protocol = "Tcp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-kubernetes"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubernetes traffic from cluster hosts"
    protocol = "Tcp"
    source_port_range = "10249-10259"
    destination_port_range = "10249-10259"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-vxlan-geneve-1"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "105"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-vxlan-geneve-2"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "6081"
    destination_port_range = "6081"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "106"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-host-services-udp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "107"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-node-port"
    resource_group_name = azurerm_resource_group.main.name
    description = "NodePort traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "30000-32767"
    destination_port_range = "30000-32767"
    source_application_security_group_ids = [
      azurerm_network_security_group.bootstrap.id,
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "108"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-machine-config"
    resource_group_name = azurerm_resource_group.main.name
    description = "MachineConfig from load balancer"
    protocol = "Tcp"
    source_port_range = "22623"
    destination_port_range = "22623"
    source_application_security_group_ids = [
      azurerm_network_security_group.api-lb.id
    ]
    access = "Allow"
    priority = "109"
    direction = "Inbound"
  }

  tags = {
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface.html
resource "azurerm_network_interface" "master" {
  count = 3
  name = "openshift-${var.cluster_name}-master-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_security_group_id = azurerm_network_security_group.master.id
  ip_configuration {
    name = "openshift-${var.cluster_name}-master-nic-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
}

# https://www.terraform.io/docs/providers/azurerm/r/network_interface_backend_address_pool_association.html
resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count = 3
  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  ip_configuration_name   = "openshift-${var.cluster_name}-master-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
}

# https://www.terraform.io/docs/providers/azurerm/r/network_security_group.html
resource "azurerm_network_security_group" "worker" {
  name = "openshift-${var.cluster_name}-worker"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-worker-host-services-tcp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from cluster hosts"
    protocol = "Tcp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-kubernetes"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubernetes traffic from cluster hosts"
    protocol = "Tcp"
    source_port_range = "10249-10259"
    destination_port_range = "10249-10259"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-vxlan-geneve-1"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-vxlan-geneve-2"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "6081"
    destination_port_range = "6081"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-host-services-udp"
    resource_group_name = azurerm_resource_group.main.name
    description = "Host services traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "9000-9999"
    destination_port_range = "9000-9999"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "105"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-node-port"
    resource_group_name = azurerm_resource_group.main.name
    description = "NodePort traffic from cluster hosts"
    protocol = "Udp"
    source_port_range = "30000-32767"
    destination_port_range = "30000-32767"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "106"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-ingress-http"
    resource_group_name = azurerm_resource_group.main.name
    description = "Ingress http from load balancer"
    protocol = "Tcp"
    source_port_range = "80"
    destination_port_range = "80"
    source_application_security_group_ids = [
      azurerm_network_security_group.ingress-lb.id
    ]
    access = "Allow"
    priority = "107"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-ingress-https"
    resource_group_name = azurerm_resource_group.main.name
    description = "Ingress http from load balancer"
    protocol = "Tcp"
    source_port_range = "443"
    destination_port_range = "443"
    source_application_security_group_ids = [
      azurerm_network_security_group.ingress-lb.id
    ]
    access = "Allow"
    priority = "108"
    direction = "Inbound"
  }

  tags = {
  }
}


