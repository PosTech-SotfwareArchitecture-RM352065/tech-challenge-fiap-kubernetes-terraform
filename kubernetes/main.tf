
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}



resource "local_file" "kubeconfig" {
  content  = var.kubeconfig
  filename = "${path.root}/kubeconfig"
}

resource "kubernetes_secret" "api_secrets" {
  metadata {
    name = "api-secrets"
  }

  data = {
    MAIN_CONNECTION_STRING = var.main_database_connectionstring
    CART_CONNECTION_STRING = var.cart_database_connectionstring
    AUTH_SECRET_KEY        = var.authentication_secret_key
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "api_config" {
  metadata {
    name = "api-config"
  }

  data = {
    ASPNETCORE_URLS        = "http://+:9000"
    ASPNETCORE_ENVIRONMENT = var.environment
    MAIN_CONNECTION_TYPE   = "MSSQL"
    CART_CONNECTION_TYPE   = "REDIS"
    AUTH_ISSUER            = "Sanduba.Auth"
    AUTH_AUDIENCE          = "Users"
  }
}

resource "kubernetes_deployment" "api_deployment" {
  metadata {
    name = "sanduba-api-deployment"
    labels = {
      app = "sanduba-api-deployment"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sanduba-api-deployment"
      }
    }

    template {
      metadata {
        labels = {
          app = "sanduba-api-deployment"
        }
      }

      spec {
        container {
          image = "cangelosilima/restaurantesanduba.api:latest"
          name  = "restaurantesanduba-pod-api"

          port {
            container_port = 9000
          }

          env {
            name = "ConnectionStrings__MainDatabase__Type"
            value_from {
              config_map_key_ref {
                key  = "MAIN_CONNECTION_TYPE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__MainDatabase__value"
            value_from {
              secret_key_ref {
                key  = "MAIN_CONNECTION_STRING"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__CartDatabase__Type"
            value_from {
              config_map_key_ref {
                key  = "CART_CONNECTION_TYPE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__CartDatabase_type"
            value_from {
              config_map_key_ref {
                key  = "CART_CONNECTION_TYPE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "ConnectionStrings__CartDatabase__Value"
            value_from {
              secret_key_ref {
                key  = "CART_CONNECTION_STRING"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__SecretKey"
            value_from {
              secret_key_ref {
                key  = "AUTH_SECRET_KEY"
                name = kubernetes_secret.api_secrets.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__Issuer"
            value_from {
              config_map_key_ref {
                key  = "AUTH_ISSUER"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          env {
            name = "JwtSettings__Audience"
            value_from {
              config_map_key_ref {
                key  = "AUTH_AUDIENCE"
                name = kubernetes_config_map.api_config.metadata[0].name
              }
            }
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 9000
            }

            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_service" {
  metadata {
    name = "sanduba-api-svc"
    labels = {
      app = "sanduba-api-svc"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.api_deployment.metadata[0].labels["app"]
    }
    port {
      protocol    = "TCP"
      port        = 9000
      target_port = 9000
    }

    type = "NodePort"
  }
}
