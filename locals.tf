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

  cluster_ipv4cidr = "10.244.0.0/24"
  cluster_ipv6cidr = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 2)

  kube_apiserver_ipv4cidr = "10.67.0.0/24"
  kube_apiserver_ipv6cidr = cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 1)

  cluster_cidrs = toset(
    concat(
      oci_core_subnet.cluster.ipv4cidr_blocks,
      oci_core_subnet.cluster.ipv6cidr_blocks
    )
  )

  kube_apiserver_tcp_in = {
    for i in setproduct(
      local.cluster_cidrs,
      [6443, 12250]
    ) : "${i[0]}:${i[1]}" => i
  }

  kube_apiserver_icmp_in = {
    for i in setproduct(
      local.cluster_cidrs,
      [3, 4]
    ) : "${i[0]}:${i[1]}" => i
  }

  cluster_local_cidrs = toset(concat(
    oci_core_subnet.cluster.ipv4cidr_blocks,
    oci_core_subnet.cluster.ipv6cidr_blocks,
    oci_core_subnet.kube_apiserver.ipv4cidr_blocks,
    oci_core_subnet.kube_apiserver.ipv6cidr_blocks,
  ))

  cluster_tcp_out = { for port in [80, 443] : "${port}" => port }
}
