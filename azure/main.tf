terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
}

resource "azurerm_resource_group" "resource_group" {
  name       = "fiap-tech-challenge-k8s-group"
  location   = "eastus"
  managed_by = "fiap-tech-challenge-group"

  tags = {
    environment = "development"
  }
}

data "azurerm_resource_group" "main_group" {
  name = "fiap-tech-challenge-main-group"
}

data "azurerm_virtual_network" "virtual_network" {
  name                = "fiap-tech-challenge-network"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

data "azurerm_subnet" "k8s_subnet" {
  name                 = "fiap-tech-challenge-k8s-subnet"
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "fiap-tech-challenge-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "sanduba-k8s"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = data.azurerm_subnet.k8s_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
  }

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config_raw
  sensitive = true
}