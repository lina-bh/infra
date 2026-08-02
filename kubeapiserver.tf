resource "oci_core_subnet" "kubeapiserver" {
  compartment_id  = oci_core_vcn.vcn.compartment_id
  vcn_id          = oci_core_vcn.vcn.id
  dns_label       = "kubeapiserver0"
  ipv4cidr_blocks = [local.kube_apiserver_ipv4cidr]
  ipv6cidr_blocks = [local.kube_apiserver_ipv6cidr]
  display_name    = "kubeapiserver"
}

resource "oci_core_network_security_group" "kubeapiserver" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  display_name = "kubeapiserver"
}

resource "oci_core_network_security_group_security_rule" "kube_apiserver_in_home" {
  network_security_group_id = oci_core_network_security_group.kubeapiserver.id

  direction   = "INGRESS"
  source      = var.home_prefix
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.TCP

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kube_apiserver_oci_services" {
  network_security_group_id = oci_core_network_security_group.kubeapiserver.id

  direction        = "EGRESS"
  destination      = "all-lhr-services-in-oracle-services-network"
  destination_type = "SERVICE_CIDR_BLOCK"
  protocol         = local.security_list_protocol.TCP
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kube_apiserver_tcp_in" {
  for_each = {
    for i in setproduct(
      local.cluster_cidrs,
      var.kubeapiserver_tcp_in
    ) : "${i[0]}:${i[1]}" => i
  }

  network_security_group_id = oci_core_network_security_group.kubeapiserver.id

  direction   = "INGRESS"
  source      = each.value[0]
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.TCP
  tcp_options {
    destination_port_range {
      min = each.value[1]
      max = each.value[1]
    }
  }
}

resource "oci_core_network_security_group_security_rule" "kube_apiserver_icmp_in" {
  for_each = {
    for i in setproduct(
      local.cluster_cidrs,
      var.kubeapiserver_icmp_in
    ) : "${i[0]}:${i[1]}" => i
  }

  network_security_group_id = oci_core_network_security_group.kubeapiserver.id

  direction   = "INGRESS"
  source      = each.value[0]
  source_type = "CIDR_BLOCK"
  protocol    = local.security_list_protocol.ICMP
  icmp_options {
    type = each.value[1]
  }
}
