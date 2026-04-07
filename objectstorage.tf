resource "oci_objectstorage_bucket" "longhorn" {
  compartment_id = data.oci_objectstorage_namespace.ns.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "longhorn"

  auto_tiering = "InfrequentAccess"
}

resource "oci_identity_user" "longhorn_service_account" {
  compartment_id = oci_objectstorage_bucket.longhorn.compartment_id

  name        = "longhorn_service_account"
  description = "Service account for longhorn bucket"
}

resource "oci_identity_customer_secret_key" "longhorn_service_account" {
  display_name = "longhorn_service_account"
  user_id      = oci_identity_user.longhorn_service_account.id
}

resource "oci_identity_group" "longhorn_service_account" {
  compartment_id = oci_identity_user.longhorn_service_account.compartment_id

  name        = "longhorn_service_account"
  description = "Group for longhorn_service_account"
}

resource "oci_identity_user_group_membership" "longhorn_service_account" {
  user_id  = oci_identity_user.longhorn_service_account.id
  group_id = oci_identity_group.longhorn_service_account.id
}

resource "oci_identity_policy" "longhorn_service_account" {
  compartment_id = oci_identity_user.longhorn_service_account.compartment_id

  name        = "longhorn_service_account"
  description = "Permit longhorn_service_account to read and write to longhorn bucket"

  statements = [
    "Allow group id ${oci_identity_group.longhorn_service_account.id} to read buckets in tenancy where target.bucket.name = '${oci_objectstorage_bucket.longhorn.name}'",
    "Allow group id ${oci_identity_group.longhorn_service_account.id} to manage objects in tenancy where target.bucket.name = '${oci_objectstorage_bucket.longhorn.name}'"
  ]
}

