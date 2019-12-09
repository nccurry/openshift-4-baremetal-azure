provider "azurerm" {
  disable_terraform_partner_id = true
}

resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group_name
  location = var.cluster_location
}

data azurerm_subnet "cluster" {
  name = var.cluster_subnetwork_name
  virtual_network_name = var.cluster_network_name
  resource_group_name = var.azure_resource_group_name
}

data "azurerm_dns_zone" "cluster" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

data "template_file" "master" {
  template = file("cloudconfig.tpl")
}

# Load Balancers

resource "azurerm_network_security_group" "api-lb" {
  name = "openshift-${var.cluster_name}-api-lb"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-api-lb-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "API traffic from external"
    protocol = "Tcp"
    source_port_range = "8443"
    destination_port_range = "8443"
    source_address_prefix = "*"
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  tags = {
  }
}

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

resource "azurerm_lb_backend_address_pool" "api-lb" {
  name = "openshift-${var.cluster_name}-api-lb"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.api-lb.id
}

resource "azurerm_lb_rule" "api-lb-https" {
  name = "openshift-${var.cluster_name}-api-lb-https"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  frontend_ip_configuration_name = "openshift-${var.cluster_name}-api-lb-config"
  protocol = "Tcp"
  frontend_port = "8443"
  backend_port = "8443"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
  probe_id = azurerm_lb_probe.api-lb-https.id
}

resource "azurerm_lb_probe" "api-lb-https" {
  name = "openshift-${var.cluster_name}-api-lb-https"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.api-lb.id
  protocol = "Https"
  port = "8443"
  request_path = "/healthz"
}

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

  security_rule {
    name = "openshift-${var.cluster_name}-ingress-lb-haproxy-stats"
    resource_group_name = azurerm_resource_group.main.name
    description = "Ingress http from external"
    protocol = "Tcp"
    source_port_range = "1936"
    destination_port_range = "1936"
    source_address_prefix = "*"
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  tags = {
  }
}

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

resource "azurerm_lb_backend_address_pool" "ingress-lb" {
  name = "openshift-${var.cluster_name}-ingress-lb"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.ingress-lb.id
}

resource "azurerm_lb_rule" "ingress-lb-https" {
  name = "openshift-${var.cluster_name}-ingress-lb-https"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  frontend_ip_configuration_name = "openshift-${var.cluster_name}-ingress-lb-config"
  protocol = "Tcp"
  frontend_port = "443"
  backend_port = "443"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id = azurerm_lb_probe.ingress-lb-haproxy-health.id
}

resource "azurerm_lb_rule" "ingress-lb-http" {
  name = "openshift-${var.cluster_name}-ingress-lb-http"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  frontend_ip_configuration_name = "openshift-${var.cluster_name}-ingress-lb-config"
  protocol = "Tcp"
  frontend_port = "80"
  backend_port = "80"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id = azurerm_lb_probe.ingress-lb-haproxy-health.id
}

resource "azurerm_lb_probe" "ingress-lb-haproxy-health" {
  name = "openshift-${var.cluster_name}-ingress-lb-haproxy-health"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  protocol = "Http"
  port = "1936"
  request_path = "/healthz"
}

resource "azurerm_lb_rule" "ingress-lb-haproxy-stats" {
  name = "openshift-${var.cluster_name}-ingress-lb-haproxy-stats"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  frontend_ip_configuration_name = "openshift-${var.cluster_name}-ingress-lb-config"
  protocol = "Tcp"
  frontend_port = "1936"
  backend_port = "1936"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id = azurerm_lb_probe.ingress-lb-haproxy-stats.id
}

resource "azurerm_lb_probe" "ingress-lb-haproxy-stats" {
  name = "openshift-${var.cluster_name}-ingress-lb-haproxy-stats"
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id = azurerm_lb.ingress-lb.id
  protocol = "Tcp"
  port = "1936"
}

# Master

resource "azurerm_network_security_group" "master" {
  name = "openshift-${var.cluster_name}-master"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-master-sdn"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-dns-tcp"
    resource_group_name = azurerm_resource_group.main.name
    description = "DNS traffic"
    protocol = "Tcp"
    source_port_range = "8053"
    destination_port_range = "8053"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-dns-udp"
    resource_group_name = azurerm_resource_group.main.name
    description = "DNS traffic"
    protocol = "Udp"
    source_port_range = "8053"
    destination_port_range = "8053"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-kubelet"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubelet traffic"
    protocol = "Tcp"
    source_port_range = "10250"
    destination_port_range = "10250"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id,
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "API traffic"
    protocol = "Tcp"
    source_port_range = "8443"
    destination_port_range = "8443"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id,
      azurerm_network_security_group.api-lb.id
    ]
    access = "Allow"
    priority = "105"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-etcd"
    resource_group_name = azurerm_resource_group.main.name
    description = "Etcd traffic"
    protocol = "Tcp"
    source_port_range = "2379-2380"
    destination_port_range = "2379-2380"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id
    ]
    access = "Allow"
    priority = "106"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-controller-service"
    resource_group_name = azurerm_resource_group.main.name
    description = "Controller service traffic"
    protocol = "Tcp"
    source_port_range = "8444"
    destination_port_range = "8444"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id,
    ]
    access = "Allow"
    priority = "107"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-ssh"
    resource_group_name = azurerm_resource_group.main.name
    description = "SSH traffic"
    protocol = "Tcp"
    source_port_range = "22"
    destination_port_range = "22"
    source_address_prefix = "*"
    access = "Allow"
    priority = "108"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-master-prometheus-metrics"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus metrics traffic"
    protocol = "Tcp"
    source_port_range = "9100"
    destination_port_range = "9100"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "109"
    direction = "Inbound"
  }

  tags = {
  }
}

resource "azurerm_availability_set" "master" {
  name                = "openshift-${var.cluster_name}-master"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  managed = true
  tags = {
  }
}

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

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count = 3
  network_interface_id    = element(azurerm_network_interface.master.*.id, count.index)
  ip_configuration_name   = "openshift-${var.cluster_name}-master-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.api-lb.id
}

resource "azurerm_managed_disk" "master" {
  count=3
  name = "openshift-${var.cluster_name}-master-${count.index}-disk"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  storage_account_type = "Premium_LRS"
  create_option = "FromImage"
  image_reference_id = var.image_id
  disk_size_gb = 200
  tags = {

  }
}

resource "azurerm_virtual_machine" "master" {
  count = 3
  name = "openshift-${var.cluster_name}-master-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_interface_ids = [
    azurerm_network_interface.master.id
  ]
  os_profile_linux_config = {
    disable_password_authentication = true
    ssh_keys = {
      key_data = file(var.ssh_key_path)
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
    }
  }
  vm_size = var.master_vm_size
  availability_set_id = azurerm_availability_set.master.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  identity {
    type = "UserAssigned "
    identity_ids = [
      var.cluster_identity_id
    ]
  }

  os_profile {
    computer_name = "openshift-${var.cluster_name}-master-${count.index}"
    admin_username = var.admin_user
  }

  storage_os_disk {
    name = "openshift-${var.cluster_name}-master-${count.index}-disk"
    create_option = "Attach"
    caching = "ReadOnly"
    managed_disk_id = element(azurerm_managed_disk.master.*.id, count.index)
  }

  tags {
  }
}

# Infra

resource "azurerm_network_security_group" "infra" {
  name = "openshift-${var.cluster_name}-infra"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-infra-sdn"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-kubelet"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubelet traffic"
    protocol = "Tcp"
    source_port_range = "10250"
    destination_port_range = "10250"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id,
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-ssh"
    resource_group_name = azurerm_resource_group.main.name
    description = "SSH traffic"
    protocol = "Tcp"
    source_port_range = "22"
    destination_port_range = "22"
    source_address_prefix = "*"
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-haproxy-stats"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubelet traffic"
    protocol = "Tcp"
    source_port_range = "1936"
    destination_port_range = "1936"
    source_application_security_group_ids = [
      azurerm_network_security_group.ingress-lb.id
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-elasticsearch-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "Elasticsearch api traffic"
    protocol = "Tcp"
    source_port_range = "9200"
    destination_port_range = "9200"
    source_application_security_group_ids = [
      azurerm_network_security_group.infra.id
    ]
    access = "Allow"
    priority = "105"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-elasticsearch-cluster"
    resource_group_name = azurerm_resource_group.main.name
    description = "Elasticsearch cluster traffic"
    protocol = "Tcp"
    source_port_range = "9300"
    destination_port_range = "9300"
    source_application_security_group_ids = [
      azurerm_network_security_group.infra.id
    ]
    access = "Allow"
    priority = "106"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-prometheus-api"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus api traffic"
    protocol = "Tcp"
    source_port_range = "9090"
    destination_port_range = "9090"
    source_application_security_group_ids = [
      azurerm_network_security_group.infra.id
    ]
    access = "Allow"
    priority = "107"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-prometheus-metrics"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus metrics traffic"
    protocol = "Tcp"
    source_port_range = "9100"
    destination_port_range = "9100"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "108"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-ingress-http"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus metrics traffic"
    protocol = "Tcp"
    source_port_range = "80"
    destination_port_range = "80"
    source_application_security_group_ids = [
      azurerm_network_security_group.ingress-lb.id
    ]
    access = "Allow"
    priority = "109"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-infra-ingress-https"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus metrics traffic"
    protocol = "Tcp"
    source_port_range = "443"
    destination_port_range = "443"
    source_application_security_group_ids = [
      azurerm_network_security_group.ingress-lb.id
    ]
    access = "Allow"
    priority = "110"
    direction = "Inbound"
  }
}

resource "azurerm_availability_set" "infra" {
  name                = "openshift-${var.cluster_name}-infra"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  managed = true
  tags = {
  }
}

resource "azurerm_network_interface" "infra" {
  count = 3
  name = "openshift-${var.cluster_name}-infra-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_security_group_id = azurerm_network_security_group.infra.id
  ip_configuration {
    name = "openshift-${var.cluster_name}-infra-nic-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "infra" {
  count = 3
  network_interface_id    = element(azurerm_network_interface.infra.*.id, count.index)
  ip_configuration_name   = "openshift-${var.cluster_name}-infra-nic-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
}

resource "azurerm_managed_disk" "infra" {
  count=3
  name = "openshift-${var.cluster_name}-infra-${count.index}-disk"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  storage_account_type = "Premium_LRS"
  create_option = "FromImage"
  image_reference_id = var.image_id
  disk_size_gb = 200
  tags = {

  }
}

resource "azurerm_virtual_machine" "infra" {
  count = 3
  name = "openshift-${var.cluster_name}-infra-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_interface_ids = [
    azurerm_network_interface.master.id
  ]
  os_profile_linux_config = {
    disable_password_authentication = true
    ssh_keys = {
      key_data = file(var.ssh_key_path)
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
    }
  }
  vm_size = var.infra_vm_size
  availability_set_id = azurerm_availability_set.master.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  identity {
    type = "UserAssigned "
    identity_ids = [
      var.cluster_identity_id
    ]
  }

  os_profile {
    computer_name = "openshift-${var.cluster_name}-infra-${count.index}"
    admin_username = var.admin_user
  }

  storage_os_disk {
    name = "openshift-${var.cluster_name}-infra-${count.index}-disk"
    create_option = "Attach"
    caching = "ReadOnly"
    managed_disk_id = element(azurerm_managed_disk.infra.*.id, count.index)
  }

  tags {
  }
}

# Worker

resource "azurerm_network_security_group" "worker" {
  name = "openshift-${var.cluster_name}-worker"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location

  security_rule {
    name = "openshift-${var.cluster_name}-worker-sdn"
    resource_group_name = azurerm_resource_group.main.name
    description = "SDN traffic"
    protocol = "Udp"
    source_port_range = "4789"
    destination_port_range = "4789"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "101"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-kubelet"
    resource_group_name = azurerm_resource_group.main.name
    description = "Kubelet traffic"
    protocol = "Tcp"
    source_port_range = "10250"
    destination_port_range = "10250"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id,
    ]
    access = "Allow"
    priority = "102"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-ssh"
    resource_group_name = azurerm_resource_group.main.name
    description = "SSH traffic"
    protocol = "Tcp"
    source_port_range = "22"
    destination_port_range = "22"
    source_address_prefix = "*"
    access = "Allow"
    priority = "103"
    direction = "Inbound"
  }

  security_rule {
    name = "openshift-${var.cluster_name}-worker-prometheus-metrics"
    resource_group_name = azurerm_resource_group.main.name
    description = "Prometheus metrics traffic"
    protocol = "Tcp"
    source_port_range = "9100"
    destination_port_range = "9100"
    source_application_security_group_ids = [
      azurerm_network_security_group.master.id,
      azurerm_network_security_group.infra.id,
      azurerm_network_security_group.worker.id
    ]
    access = "Allow"
    priority = "104"
    direction = "Inbound"
  }

  tags = {
  }
}

resource "azurerm_availability_set" "worker" {
  name                = "openshift-${var.cluster_name}-worker"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  managed = true
  tags = {
  }
}

resource "azurerm_network_interface" "worker" {
  count = 3
  name = "openshift-${var.cluster_name}-worker-nic-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_security_group_id = azurerm_network_security_group.worker.id
  ip_configuration {
    name = "openshift-${var.cluster_name}-worker-nic-config"
    subnet_id = data.azurerm_subnet.cluster.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_managed_disk" "worker" {
  count=3
  name = "openshift-${var.cluster_name}-worker-${count.index}-disk"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  storage_account_type = "Premium_LRS"
  create_option = "FromImage"
  image_reference_id = var.image_id
  disk_size_gb = 200
  tags = {

  }
}

resource "azurerm_virtual_machine" "worker" {
  count = 3
  name = "openshift-${var.cluster_name}-worker-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location = var.cluster_location
  network_interface_ids = [
    azurerm_network_interface.worker.id
  ]
  os_profile_linux_config = {
    disable_password_authentication = true
    ssh_keys = {
      key_data = file(var.ssh_key_path)
      path = "/home/${var.admin_user}/.ssh/authorized_keys"
    }
  }
  vm_size = var.infra_vm_size
  availability_set_id = azurerm_availability_set.worker.id
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true
  identity {
    type = "UserAssigned "
    identity_ids = [
      var.cluster_identity_id
    ]
  }

  os_profile {
    computer_name = "openshift-${var.cluster_name}-worker-${count.index}"
    admin_username = var.admin_user
  }

  storage_os_disk {
    name = "openshift-${var.cluster_name}-worker-${count.index}-disk"
    create_option = "Attach"
    caching = "ReadOnly"
    managed_disk_id = element(azurerm_managed_disk.worker.*.id, count.index)
  }

  tags {
  }
}

# DNS Entries

resource "azurerm_dns_a_record" "api-public" {
  name = "api.${var.cluster_name}"
  resource_group_name = var.azure_resource_group_name
  zone_name = data.azurerm_dns_zone.cluster.name
  ttl = 300
  records = [
    azurerm_lb.api-lb.private_ip_address
  ]
  tags = {}
}

resource "azurerm_dns_a_record" "api-private" {
  name = "api-int.${var.cluster_name}"
  resource_group_name = var.azure_resource_group_name
  zone_name = data.azurerm_dns_zone.cluster.name
  ttl = 300
  records = [
    azurerm_lb.api-lb.private_ip_address
  ]
  tags = {}
}

resource "azurerm_dns_a_record" "ingress" {
  name = "*.apps.${var.cluster_name}"
  resource_group_name = var.azure_resource_group_name
  zone_name = data.azurerm_dns_zone.cluster.name
  ttl = 300
  records = [
    azurerm_lb.ingress-lb.private_ip_address
  ]
  tags = {}
}
