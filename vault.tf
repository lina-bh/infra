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

resource "kubernetes_manifest" "clustersecretstore_oci" {
  depends_on = [kubernetes_manifest.helmrelease_external-secrets]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "oci"
    }
    spec = {
      provider = {
        oracle = {
          vault         = oci_kms_vault.vault.id
          region        = "uk-london-1"
          principalType = "InstancePrincipal"
        }
      }
    }
  }
}
