data "oci_core_services" "svcs" {}

resource "oci_core_vcn" "vcn" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  display_name   = "vcn"
  dns_label      = "vcn0"
  cidr_blocks    = [local.kube_apiserver_ipv4cidr, local.cluster_ipv4cidr]
  is_ipv6enabled = true
}

resource "oci_core_internet_gateway" "inet" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id
}

resource "oci_core_service_gateway" "svc" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id

  display_name = "svcs"

  services {
    service_id = data.oci_core_services.svcs.services[
      index(
        data.oci_core_services.svcs.services.*.cidr_block,
        "all-lhr-services-in-oracle-services-network"
      )
    ].id
  }
}

resource "oci_core_default_route_table" "route" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_route_table_id

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_internet_gateway.inet.id
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_default_security_list" "acl" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  manage_default_resource_id = oci_core_vcn.vcn.default_security_list_id
}
