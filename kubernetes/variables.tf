variable "main_database_connectionstring" {
  type      = string
  sensitive = true
}

variable "cart_database_connectionstring" {
  type      = string
  sensitive = true
}

variable "authentication_secret_key" {
  type      = string
  sensitive = true
}

variable "environment" {
  type    = string
  default = "Development"
}