terraform {
  backend "s3" {
    bucket = "tfstate"
    key    = "terraform.tfstate"

    use_path_style = true
    insecure       = true

    region                 = "us-east-1"
    skip_region_validation = true

    skip_metadata_api_check     = true
    skip_credentials_validation = true
  }

  required_providers {
    tailscale = {
      source = "tailscale/tailscale"
      version = "0.28.0"
    }
    oci = {
      source = "oracle/oci"
      version = "8.3.0"
    }
    local      = {
      source = "hashicorp/local"
      version = "2.7.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "3.0.1"
    }
  }
}

provider "oci" {
  private_key_path = "${path.root}/.oci/pem"
}

provider "tailscale" {
  api_key = var.tskey_api
}

provider "kubernetes" {
  config_path = "${path.root}/.kube/config"
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}
