resource "oci_identity_dynamic_group" "instances" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  name           = "instances"
  description    = "all instances in default compartment"
  matching_rule  = "instance.compartment.id = '${data.oci_identity_availability_domains.ad.compartment_id}'"
}

resource "oci_identity_policy" "instance_principal" {
  compartment_id = oci_identity_dynamic_group.instances.compartment_id
  name           = "instance_principal"
  description    = "permit instances to access oci"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.instances.name} to read secret-family in tenancy"
  ]
}
