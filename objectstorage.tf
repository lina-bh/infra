resource "oci_objectstorage_bucket" "cnpg" {
  compartment_id = data.oci_objectstorage_namespace.ns.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "cnpg"
  auto_tiering   = "InfrequentAccess"
}


