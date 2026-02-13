resource "tailscale_tailnet_key" "tskey_auth" {
  ephemeral     = false
  preauthorized = true
  reusable      = true
  tags          = ["tag:oci"]
}

module "cloudinit-tailscale" {
  source = "github.com/tailscale/terraform-cloudinit-tailscale"

  accept_dns       = false
  advertise_tags   = ["tag:oci"]
  advertise_routes = [oci_core_vcn.vcn.cidr_blocks[0]]
  auth_key         = tailscale_tailnet_key.tskey_auth.key
  additional_parts = [
    {
      filename     = "ssh.yaml"
      content_type = "text/cloud-config"
      content      = <<-EOT
#cloud-config
ssh_authorized_keys:
  - "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMOCu6tMJ6EcyMpVEOQOF4UYCog1vB1xZha+UzM5U8f"
EOT
    }
  ]
}

resource "oci_core_instance" "server" {
  lifecycle {
    ignore_changes = [metadata, source_details]
  }

  compartment_id      = oci_core_subnet.sn.compartment_id
  availability_domain = local.availability_domains["3"]

  availability_config {
    # is_live_migration_preferred = true
  }

  shape = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 3
    memory_in_gbs = 18
  }

  launch_options {
    firmware     = "UEFI_64"
    network_type = "PARAVIRTUALIZED"
    # boot_volume_type = "PARAVIRTUALIZED"

    is_consistent_volume_naming_enabled = true
  }

  create_vnic_details {
    # hostname_label = "server"
    subnet_id = oci_core_subnet.sn.id
  }

  agent_config {
    are_all_plugins_disabled = true
  }

  display_name = "server"

  metadata = {
    "user_data" = module.cloudinit-tailscale.rendered
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.fedora_aarch64.id
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 20
  }

  preserve_boot_volume = false
  # is_pv_encryption_in_transit_enabled = true
}

data "tailscale_device" "server" {
  hostname = oci_core_instance.server.display_name
  wait_for = "90s"
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.root}/inventory.ini"
  file_permission = "0644"
  content         = <<EOF
[server]
${data.tailscale_device.server.addresses[0]} ansible_user=fedora ansible_become=true ansible_ssh_private_key_file=~/.ssh/server
EOF
}
