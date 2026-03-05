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

variable "cluster_tcp_out" {
  type = set(number)
}

variable "cluster_udp_out" {
  type = set(number)
}

variable "kubeapiserver_tcp_in" {
  type = set(number)
}

variable "kubeapiserver_icmp_in" {
  type    = set(number)
  default = [3, 4]
}
