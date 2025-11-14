data "oci_core_images" "ubuntu" {
  compartment_id           = oci_core_subnet.sn.compartment_id
  shape                    = "VM.Standard.E2.1.Micro"
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_vcn" "pub" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id

  cidr_blocks = ["10.0.1.0/24"]
}

resource "oci_core_internet_gateway" "inet" {
  compartment_id = oci_core_vcn.pub.compartment_id
  vcn_id         = oci_core_vcn.pub.id
}

resource "oci_core_default_route_table" "pub" {
  compartment_id             = oci_core_vcn.pub.compartment_id
  manage_default_resource_id = oci_core_vcn.pub.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "pub" {
  compartment_id = oci_core_vcn.pub.compartment_id

  vcn_id     = oci_core_vcn.pub.id
  cidr_block = oci_core_vcn.pub.cidr_blocks[0]
}

resource "oci_core_default_security_list" "pub" {
  compartment_id             = oci_core_vcn.pub.compartment_id
  manage_default_resource_id = oci_core_vcn.pub.default_security_list_id
  ingress_security_rules {
    source   = "5.151.0.0/16"
    protocol = local.security_list_protocol.TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.TCP
    tcp_options {
      min = 1
      max = 25565
    }
  }
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.UDP
    udp_options {
      min = 1
      max = 25565
    }
  }
}

data "cloudinit_config" "srcds" {
  part {
    filename     = "common.yaml"
    content_type = "text/cloud-config"
    content      = sensitive(file("${path.root}/instance/common.yaml"))
  }
}

resource "oci_core_instance" "srcds" {
  count = 0
  
  lifecycle {
    ignore_changes = [source_details]
  }
  compartment_id      = oci_core_subnet.pub.compartment_id
  availability_domain = data.oci_identity_availability_domains.ad.availability_domains[2].name
  shape               = "VM.Standard.E2.1.Micro"
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 20
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.pub.id
    assign_public_ip = true
  }
  agent_config {
    are_all_plugins_disabled = true
  }
  display_name = "srcds"
  metadata = {
    "user_data" = data.cloudinit_config.srcds.rendered
  }
}

# output "srcds_public_ip" {
#   value = oci_core_instance.srcds.public_ip
# }
