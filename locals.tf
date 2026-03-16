locals {
  availability_domains = {
    "1" = data.oci_identity_availability_domains.ad.availability_domains[0].name
    "3" = data.oci_identity_availability_domains.ad.availability_domains[2].name
  }

  security_list_protocol = {
    ICMP    = "1"
    TCP     = "6"
    UDP     = "17"
    ICMPSIX = "58"
  }

  cluster_ipv4cidr = "10.70.0.0/24"
  cluster_ipv6cidr = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 3)

  kube_apiserver_ipv4cidr = "10.67.0.0/24"
  kube_apiserver_ipv6cidr = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 1)

  cluster_cidrs = toset(
    concat(
      oci_core_subnet.cluster.ipv4cidr_blocks,
      oci_core_subnet.cluster.ipv6cidr_blocks
    )
  )
}
