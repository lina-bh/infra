resource "oci_core_subnet" "kube_apiserver" {
  compartment_id  = oci_core_vcn.vcn.compartment_id
  vcn_id          = oci_core_vcn.vcn.id
  dns_label       = "kubeapiserver0"
  ipv4cidr_blocks = [local.kube_apiserver_ipv4cidr]
  ipv6cidr_blocks = [local.kube_apiserver_ipv6cidr]
  display_name    = "kube_apiserver"
}

resource "oci_core_route_table" "cluster" {
  compartment_id = oci_core_vcn.vcn.compartment_id

  vcn_id = oci_core_vcn.vcn.id

  route_rules {
    network_entity_id = oci_core_nat_gateway.nat.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.svc.id
    destination       = "all-lhr-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_subnet" "cluster" {
  compartment_id             = oci_core_vcn.vcn.compartment_id
  vcn_id                     = oci_core_vcn.vcn.id
  dns_label                  = "cluster0"
  ipv4cidr_blocks            = [local.cluster_ipv4cidr]
  ipv6cidr_blocks            = [local.cluster_ipv6cidr]
  display_name               = "cluster"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.cluster.id
}

resource "oci_containerengine_cluster" "cluster" {
  compartment_id     = oci_core_vcn.vcn.compartment_id
  vcn_id             = oci_core_vcn.vcn.id
  name               = "cluster"
  kubernetes_version = "v1.34.2"
  type               = "BASIC_CLUSTER"

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.kube_apiserver.id
    nsg_ids              = [oci_core_network_security_group.kube_apiserver.id]
  }

  options {
    ip_families = ["IPv4", "IPv6"]
  }

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }
}

data "oci_containerengine_node_pool_option" "aarch64" {
  node_pool_option_id   = oci_containerengine_cluster.cluster.id
  node_pool_k8s_version = oci_containerengine_cluster.cluster.kubernetes_version
  node_pool_os_arch     = "aarch64"
}

resource "oci_containerengine_node_pool" "vm_standard_a1_flex" {
  cluster_id         = oci_containerengine_cluster.cluster.id
  compartment_id     = oci_containerengine_cluster.cluster.compartment_id
  kubernetes_version = oci_containerengine_cluster.cluster.kubernetes_version
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
      cni_type = oci_containerengine_cluster.cluster.cluster_pod_network_options[0].cni_type
      # pod_subnet_ids    = [oci_core_subnet.cluster.id]
      # pod_nsg_ids       = [oci_core_network_security_group.cluster.id]
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

data "oci_containerengine_cluster_kube_config" "kubeconfig" {
  cluster_id = oci_containerengine_cluster.cluster.id
}

resource "local_file" "kubeconfig" {
  filename        = "${path.root}/.kube/config"
  file_permission = "0644"
  content         = sensitive(data.oci_containerengine_cluster_kube_config.kubeconfig.content)
}
