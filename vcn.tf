resource "oci_core_vcn" "vcn" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id

  cidr_blocks = ["10.0.0.0/24"]
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_default_route_table" "route" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id

  route_rules {
    network_entity_id = oci_core_nat_gateway.nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "sn" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id     = oci_core_vcn.vcn.id
  cidr_block = oci_core_vcn.vcn.cidr_blocks[0]
}

resource "oci_core_default_security_list" "acl" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.TCP
    tcp_options {
      min = 443
      max = 443
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.TCP
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = local.security_list_protocol.UDP
    udp_options {
      min = 41641
      max = 41641
    }
    stateless = true
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.UDP
    udp_options {
      source_port_range {
        min = 41641
        max = 41641
      }
    }
    stateless = true
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.UDP
    udp_options {
      min = 3478
      max = 3478
    }
    stateless = true
  }

  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = local.security_list_protocol.UDP
    udp_options {
      source_port_range {
        min = 3478
        max = 3478
      }
    }
    stateless = true
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.TCP
    tcp_options {
      min = 53
      max = 53
    }
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.UDP
    udp_options {
      min = 53
      max = 53
    }
  }
}
