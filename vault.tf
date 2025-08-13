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

resource "local_file" "secrets-store-oci_yaml" {
  filename = "clustersecretstore-oci.yaml"
  content = templatefile("${path.module}/clustersecretstore-oci.yaml.tftpl", {
    oci_kms_vault_id = oci_kms_vault.vault.id
  })
  file_permission = "0644"
}
