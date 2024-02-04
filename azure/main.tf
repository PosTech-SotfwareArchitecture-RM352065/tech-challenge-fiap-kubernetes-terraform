terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    key = "terraform-k8s.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name       = "fiap-tech-challenge-k8s-group"
  location   = "eastus"
  managed_by = "fiap-tech-challenge-group"
}

resource "azurerm_storage_account" "storage_account_terraform" {
  name                     = "tf-k8s-storage-account"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "development"
  }
}

resource "azurerm_storage_container" "storage_containe_terraform" {
  name                  = "tf-k8s-storage-container"
  storage_account_name  = azurerm_storage_account.storage_account_terraform.name
  container_access_type = "private"
}

resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  name                = "fiap-tech-challenge-cluster"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  dns_prefix          = "sanduba-k8s"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "development"
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