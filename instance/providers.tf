terraform {
  required_providers {
    oci       = { source = "oracle/oci" }
    tailscale = { source = "tailscale/tailscale" }
    cloudinit = { source = "hashicorp/cloudinit" }
    ansible   = { source = "ansible/ansible" }
  }
}
