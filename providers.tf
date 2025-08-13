terraform {
  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
    }
    oci = {
      source = "oracle/oci"
    }
    ansible = { source = "ansible/ansible" }
    local   = { source = "hashicorp/local" }
  }
}

provider "oci" {
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}
