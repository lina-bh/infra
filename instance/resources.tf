resource "tailscale_tailnet_key" "auth" {
  ephemeral     = true
  preauthorized = true
  reusable      = false
  tags          = ["tag:oci"]
}

data "cloudinit_config" "meta" {
  part {
    filename     = "common.yaml"
    content_type = "text/cloud-config"
    content      = sensitive(file("${path.module}/common.yaml"))
  }

  part {
    filename     = "tailscale.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/tailscale.sh.tftpl", {
      tskey = tailscale_tailnet_key.auth.key
    })
  }
}

resource "oci_core_instance" "vm" {
  lifecycle {
    ignore_changes = [metadata, source_details]
  }

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domains[local.is_aarch64 ? "1" : "3"]

  shape = local.shape[var.arch]
  shape_config {
    ocpus         = local.is_aarch64 ? 2 : 1
    memory_in_gbs = local.is_aarch64 ? 12 : 1
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 20
  }

  launch_options {
    firmware     = "UEFI_64"
    network_type = "PARAVIRTUALIZED"
  }

  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = var.assign_public_ip
  }

  agent_config {
    are_all_plugins_disabled = true
  }

  display_name = var.name

  metadata = {
    "user_data" = data.cloudinit_config.meta.rendered
  }
}

data "tailscale_device" "taildev" {
  hostname = oci_core_instance.vm.display_name
  wait_for = "90s"
}

resource "ansible_host" "host" {
  depends_on = [data.tailscale_device.taildev]

  name   = data.tailscale_device.taildev.addresses[0]
  groups = var.ansible_groups

  variables = {
    ansible_user = "root"
  }
}
