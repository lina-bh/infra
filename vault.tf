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

resource "tailscale_oauth_client" "k8s_operator" {
  scopes = ["devices:core", "auth_keys"]
  tags   = ["tag:k8s-operator"]
}

resource "oci_vault_secret" "tailscale_operator" {
  compartment_id = oci_kms_vault.vault.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.primary.id
  secret_name    = "tailscale_operator"
  secret_content {
    content = base64encode(jsonencode({
      client_id     = tailscale_oauth_client.k8s_operator.id
      client_secret = tailscale_oauth_client.k8s_operator.key
    }))
    content_type = "BASE64"
  }
}

