terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.90.0"
    }
  }
  backend "azurerm" {
    key = "terraform-k8s.tfstate"
  }
}

data "azurerm_kubernetes_cluster" "k8s" {
  depends_on          = [module.aks-cluster] # refresh cluster state before reading
  name                = "fiap-tech-challenge-cluster"
  resource_group_name = "fiap-tech-challenge-k8s-group"
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}

provider "azurerm" {
  features {}
}

module "aks-cluster" {
  source = "./azure"
}

module "kubernetes-config" {
  depends_on                     = [module.aks-cluster]
  source                         = "./kubernetes"
  main_database_connectionstring = var.main_database_connectionstring
  cart_database_connectionstring = var.cart_database_connectionstring
  authentication_secret_key      = var.authentication_secret_key
}

resource "local_sensitive_file" "kubeconfig_file" {
  content  = data.azurerm_kubernetes_cluster.k8s.kube_config_raw
  filename = "${path.root}/kubeconfig"
}