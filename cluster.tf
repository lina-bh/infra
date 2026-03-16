locals {
  cluster_local_cidrs = toset(concat(
    oci_core_subnet.cluster.ipv4cidr_blocks,
    oci_core_subnet.cluster.ipv6cidr_blocks,
    oci_core_subnet.kubeapiserver.ipv4cidr_blocks,
    oci_core_subnet.kubeapiserver.ipv6cidr_blocks,
  ))
}

data "oci_containerengine_node_pool_option" "aarch64" {
  node_pool_option_id   = oci_containerengine_cluster.kubeapiserver.id
  node_pool_k8s_version = oci_containerengine_cluster.kubeapiserver.kubernetes_version
  node_pool_os_arch     = "aarch64"
}

resource "oci_core_route_table" "cluster" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "cluster" {
  lifecycle {
    create_before_destroy = true
  }

  compartment_id             = oci_core_vcn.vcn.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  dns_label                  = "cluster1"
  ipv4cidr_blocks            = [local.cluster_ipv4cidr]
  ipv6cidr_blocks            = [local.cluster_ipv6cidr]
  display_name               = "cluster"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.cluster.id
}

resource "oci_containerengine_node_pool" "vm_standard_a1_flex" {
  lifecycle {
    ignore_changes = [node_source_details[0].image_id]
  }

  cluster_id         = oci_containerengine_cluster.kubeapiserver.id
  compartment_id     = oci_containerengine_cluster.kubeapiserver.compartment_id
  kubernetes_version = oci_containerengine_cluster.kubeapiserver.kubernetes_version
  node_shape         = "VM.Standard.A1.Flex"
  name               = "vm_standard_a1_flex"

  node_shape_config {
    memory_in_gbs = 12
    ocpus         = 2
  }

  node_config_details {
    placement_configs {
      availability_domain = local.availability_domains["1"]
      subnet_id           = oci_core_subnet.cluster.id
    }

    placement_configs {
      availability_domain = local.availability_domains["3"]
      subnet_id           = oci_core_subnet.cluster.id
    }

    is_pv_encryption_in_transit_enabled = true
    node_pool_pod_network_option_details {
      cni_type = oci_containerengine_cluster.kubeapiserver.cluster_pod_network_options[0].cni_type
    }

    nsg_ids = [oci_core_network_security_group.cluster.id]

    size = 2
  }

  node_source_details {
    source_type             = "image"
    image_id                = data.oci_containerengine_node_pool_option.aarch64.sources[0].image_id
    boot_volume_size_in_gbs = 50
  }
}

resource "oci_core_network_security_group" "cluster" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "cluster"
}

resource "oci_core_network_security_group_security_rule" "cluster_local_in" {
  for_each = local.cluster_local_cidrs

  network_security_group_id = oci_core_network_security_group.cluster.id

  direction   = "INGRESS"
  source      = each.value
  source_type = "CIDR_BLOCK"
  protocol    = "all"
  stateless   = true
}

resource "oci_core_network_security_group_security_rule" "cluster_local_out" {
  for_each = local.cluster_local_cidrs

  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = each.value
  destination_type = "CIDR_BLOCK"
  protocol         = "all"
  stateless        = true
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp_type_3_in" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction   = "INGRESS"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp_type_4_in" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction   = "INGRESS"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = 4
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp6_in" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction   = "INGRESS"
  source      = "::/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMPSIX
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp_type_3_out" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.ICMP
  icmp_options {
    type = 3
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp_type_4_out" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.ICMP
  icmp_options {
    type = 4
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_icmp6_out" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "::/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.ICMPSIX
}

resource "oci_core_network_security_group_security_rule" "cluster_oci_services" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "all-lhr-services-in-oracle-services-network"
  destination_type = "SERVICE_CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
}

resource "oci_core_network_security_group_security_rule" "cluster_tcp_out" {
  for_each = { for port in var.cluster_tcp_out : "${port}" => port }

  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  stateless        = false
  tcp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_udp_out" {
  for_each = { for port in var.cluster_udp_out : "${port}" => port }

  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = false
  udp_options {
    destination_port_range {
      min = each.value
      max = each.value
    }
  }
}
