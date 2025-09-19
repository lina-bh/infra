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
    "Allow dynamic-group id ${oci_identity_dynamic_group.instances.id} to read secret-family in tenancy"
  ]
}

resource "oci_identity_user" "cnpg_service_account" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  name           = "cnpg_service_account"
  description    = "service account for cnpg"
}

resource "oci_identity_group" "cnpg_service_account" {
  compartment_id = oci_identity_user.cnpg_service_account.compartment_id
  name           = "cnpg_service_account"
  description    = "group for cnpg service account"
}

# resource "oci_identity_policy" "cnpg_s3" {
#   compartment_id = oci_identity_group.cnpg_service_account.compartment_id
#   name           = "cnpg_s3"
#   description    = "permit cnpg service account to read/write s3"
#   statements = [
#   ]
# }

resource "oci_identity_customer_secret_key" "cnpg_service_account" {
  display_name = "cnpg_service_account"
  user_id      = oci_identity_user.cnpg_service_account.id
}

resource "oci_vault_secret" "cnpg_s3" {
  compartment_id = oci_kms_vault.vault.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.primary.id
  secret_name    = "cnpg_s3"
  secret_content {
    content = base64encode(jsonencode({
      ACCESS_KEY_ID     = oci_identity_customer_secret_key.cnpg_service_account.id
      ACCESS_SECRET_KEY = oci_identity_customer_secret_key.cnpg_service_account.key
    }))
    content_type = "BASE64"
  }
}
