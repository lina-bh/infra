resource "oci_kms_vault" "vault" {
  compartment_id = data.oci_identity_availability_domains.ad.compartment_id
  display_name   = "vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "primary" {
  compartment_id      = data.oci_identity_availability_domains.ad.compartment_id
  management_endpoint = oci_kms_vault.vault.management_endpoint
  display_name        = "primary"
  key_shape {
    algorithm = "AES"
    length    = 32
  }
}
