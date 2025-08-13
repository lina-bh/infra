data "tailscale_devices" "devs" {
}

# https://tailscale.com/kb/1337/acl-syntax
resource "tailscale_acl" "acl" {
  acl = jsonencode({
    grants = [
      {
        src = ["autogroup:member"]
        dst = ["autogroup:self"]
        ip  = ["tcp:22", "1714-1764", "tcp:2222"]
      },
      {
        src = ["autogroup:owner"]
        dst = ["autogroup:tagged"]
        ip  = ["tcp:22"]
      },
      {
        src = ["tag:oci"]
        dst = ["tag:oci"]
        ip  = ["tcp:6443", "udp:8472"]
      },
      {
        src = ["autogroup:owner"]
        dst = ["tag:k8s-operator"]
        ip  = ["tcp:443"]
        app = {
          "tailscale.com/cap/kubernetes" = [
            {
              impersonate = {
                groups = ["system:masters"]
              }
            }
          ]
        }
      },
      {
        src = ["autogroup:owner"]
        dst = ["tag:k8s"]
        ip  = ["tcp:443"]
      }
    ]
    ssh = [
      {
        action = "accept"
        src    = ["autogroup:member"]
        dst    = ["autogroup:self"]
        users  = ["root", "autogroup:nonroot"]
      },
      {
        action = "accept"
        src    = ["autogroup:owner"]
        dst    = ["autogroup:tagged"]
        users  = ["root", "autogroup:nonroot"]
      },
    ]
    nodeAttrs = [
      {
        target = flatten(
          [
            for device in data.tailscale_devices.devs.devices : device.addresses if contains(["framework", "hmd-global-hmd-fusion"], trimsuffix(device.name, nonsensitive(".${var.tailnet}")))
          ]
        )
        attr = ["mullvad"]
      },
    ]
    tagOwners = {
      "tag:oci" : [],
      "tag:k8s-operator" : [],
      "tag:k8s" : ["tag:k8s-operator"],
    }
  })
}

resource "tailscale_oauth_client" "k8s" {
  depends_on = [tailscale_acl.acl]

  scopes = ["devices:core", "auth_keys"]
  tags   = ["tag:k8s-operator"]
}

resource "oci_vault_secret" "ts-oauth-k8s" {
  compartment_id = oci_kms_vault.vault.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.primary.id
  secret_name    = "ts-oauth-k8s"
  secret_content {
    content = base64encode(jsonencode({
      client_id     = tailscale_oauth_client.k8s.id
      client_secret = tailscale_oauth_client.k8s.key
    }))
    content_type = "BASE64"
  }
}
