resource "tailscale_tailnet_key" "arm" {
  ephemeral     = true
  preauthorized = true
  reusable      = false
  tags          = ["tag:oci"]
}

resource "random_pet" "arm" {
  separator = ""
}

data "cloudinit_config" "arm" {
  part {
    filename     = "common.yaml"
    content_type = "text/cloud-config"
    content      = sensitive(file("${path.module}/instance/common.yaml"))
  }

  part {
    filename     = "tailscale.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.root}/tailscale.sh.tftpl", {
      tskey = tailscale_tailnet_key.arm.key
    })
  }
}

resource "oci_core_instance" "arm" {
  lifecycle {
    ignore_changes = [metadata, source_details]
  }

  compartment_id      = oci_core_subnet.sn.compartment_id
  availability_domain = local.availability_domains["3"]

  shape = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type             = "image"
    source_id               = oci_core_image.fedora_aarch64.id
    boot_volume_size_in_gbs = 100
    boot_volume_vpus_per_gb = 20
  }

  launch_options {
    firmware     = "UEFI_64"
    network_type = "PARAVIRTUALIZED"
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.sn.id
  }

  agent_config {
    are_all_plugins_disabled = true
  }

  display_name = random_pet.arm.id

  metadata = {
    "user_data" = data.cloudinit_config.arm.rendered
  }
}

data "tailscale_device" "arm" {
  hostname = oci_core_instance.arm.display_name
  wait_for = "90s"
}

output "arm_public_ip" {
  value = oci_core_instance.arm.public_ip
}

resource "local_file" "ansible_inventory" {
  filename        = "${path.root}/inventory.ini"
  file_permission = "0644"
  content         = <<EOF
[fedora]
${data.tailscale_device.arm.addresses[0]} ansible_user=fedora ansible_become=true ansible_ssh_private_key_file=~/.ssh/oci
EOF
}

resource "oci_core_volume_attachment" "persistent" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.arm.id
  volume_id       = oci_core_volume.persistent.id
}
