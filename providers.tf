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
    }
    oci = {
      source = "oracle/oci"
    }
    local = { source = "hashicorp/local" }
  }
}

provider "oci" {
  private_key_path = "${path.root}/.oci/pem"
}

provider "tailscale" {
  api_key = var.tskey_api
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = var.compartment_ocid
}
