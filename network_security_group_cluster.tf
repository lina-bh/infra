locals {
  cluster_local_cidrs = toset(concat(
    oci_core_subnet.cluster.ipv4cidr_blocks,
    oci_core_subnet.cluster.ipv6cidr_blocks,
    oci_core_subnet.kube_apiserver.ipv4cidr_blocks,
    oci_core_subnet.kube_apiserver.ipv6cidr_blocks,
  ))
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
