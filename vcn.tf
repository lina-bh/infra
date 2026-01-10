locals {
  gateway_ocid = oci_core_internet_gateway.inet.id
}

resource "oci_core_vcn" "vcn" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id

  cidr_blocks = ["10.0.0.0/24"]
}

resource "oci_core_internet_gateway" "inet" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_default_route_table" "route" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id

  route_rules {
    network_entity_id = local.gateway_ocid
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "sn" {
  compartment_id = oci_core_vcn.vcn.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  # cidr_block = oci_core_vcn.vcn.cidr_blocks[0]
}

resource "oci_core_default_security_list" "acl" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id

  ingress_security_rules {
    source   = var.home_prefix
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

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.TCP
    tcp_options {
      min = 6697
      max = 6697
    }
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
  }

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = local.security_list_protocol.UDP
    udp_options {
      min = 3478
      max = 3478
    }
    stateless = false
  }
}
