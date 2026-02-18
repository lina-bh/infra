variable "compartment_ocid" {
  type = string
}

variable "tailnet" {
  type      = string
  sensitive = true
}

variable "home_prefix" {
  type = string
}

variable "tskey_api" {
  type      = string
  sensitive = true
}

variable "helm_interval" {
  type    = string
  default = "24h"
}

variable "nodes" {
  type    = number
  default = 2
}
