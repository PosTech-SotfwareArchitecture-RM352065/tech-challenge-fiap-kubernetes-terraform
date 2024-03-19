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

data "azurerm_subnet" "gateway_subnet" {
  name                 = "fiap-tech-challenge-gateway-subnet"
  virtual_network_name = data.azurerm_virtual_network.virtual_network.name
  resource_group_name  = data.azurerm_virtual_network.virtual_network.resource_group_name
}

data "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "fiap-tech-challenge-observability-workspace"
  resource_group_name = "fiap-tech-challenge-observability-group"
}

data "azurerm_application_gateway" "application_gateway" {
  name                = "fiap-tech-challenge-application-gateway"
  resource_group_name = data.azurerm_resource_group.main_group.name
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "fiap-tech-challenge-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  node_resource_group = "fiap-tech-challenge-k8s-node-group"
  dns_prefix          = "sanduba-k8s"

  
  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_B2s"
    vnet_subnet_id = data.azurerm_subnet.k8s_subnet.id
  }

  ingress_application_gateway {
    gateway_id = data.azurerm_application_gateway.application_gateway.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico" 
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.log_workspace.id
  }

  tags = {
    environment = azurerm_resource_group.resource_group.tags["environment"]
  }
}