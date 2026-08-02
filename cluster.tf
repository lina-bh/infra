locals {
  cluster_local_cidrs = toset(concat(
    oci_core_subnet.cluster.ipv4cidr_blocks,
    oci_core_subnet.cluster.ipv6cidr_blocks,
    oci_core_subnet.kubeapiserver.ipv4cidr_blocks,
    oci_core_subnet.kubeapiserver.ipv6cidr_blocks,
  ))
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

resource "oci_core_network_security_group_security_rule" "cluster_tailscale_out_dest" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = true
  udp_options {
    destination_port_range {
      min = 41641
      max = 41641
    }
  }
}


resource "oci_core_network_security_group_security_rule" "cluster_tailscale_out" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction        = "EGRESS"
  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"
  protocol         = local.security_list_protocol.UDP
  stateless        = true
  udp_options {
    source_port_range {
      min = 41641
      max = 41641
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_tailscale_in" {
  network_security_group_id = oci_core_network_security_group.cluster.id

  direction   = "INGRESS"
  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.UDP
  stateless   = true
  udp_options {
    destination_port_range {
      min = 41641
      max = 41641
    }
  }
}
