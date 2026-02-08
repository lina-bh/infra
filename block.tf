resource "oci_core_volume" "persistent" {
  compartment_id      = oci_core_vcn.vcn.compartment_id
  availability_domain = local.availability_domains["3"]

  display_name = "persistent"

  size_in_gbs = 50
  vpus_per_gb = 20
}
