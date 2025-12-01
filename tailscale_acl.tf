data "tailscale_devices" "devs" {
}

data "tailscale_device" "framework" {
  name = "framework.${var.tailnet}"
}

data "tailscale_device" "iphone-15-pro" {
  name = "iphone-15-pro.${var.tailnet}"
}

data "tailscale_device" "kobo" {
  name = "kobo.${var.tailnet}"
}

locals {
  kde-connect-devices = flatten([for device in [data.tailscale_device.framework, data.tailscale_device.iphone-15-pro] : device.addresses])
  mullvad-devices     = local.kde-connect-devices
}

# https://tailscale.com/kb/1337/acl-syntax
resource "tailscale_acl" "acl" {
  acl = jsonencode({
    grants = [
      # connect to one's own devices with SSH
      {
        src = ["autogroup:member"]
        dst = ["autogroup:self"]
        ip  = ["tcp:22"]
      },
      # tailnet owner can connect to tagged devices with SSH
      {
        src = ["autogroup:owner"]
        dst = ["autogroup:tagged"]
        ip  = ["tcp:22"]
      },
      # my devices can use kde connect and sunshine
      {
        src = local.kde-connect-devices
        dst = local.kde-connect-devices
        ip  = ["1714-1746", "tcp:47984-48010", "udp:47998-48000"]
      },
      # unprivileged ssh port for kobo
      {
        src = ["lina-bh@github"]
        dst = data.tailscale_device.kobo.addresses
        ip  = ["tcp:2222"]
      },
      # oci instances can use vxlan on 8472 udp and apiserver on 6443
      {
        src = ["tag:oci"]
        dst = ["tag:oci"]
        ip  = ["tcp:6443", "udp:8472"]
      },
      # i can connect to apiserver proxy with cluster admin role, and all k8s ingresses
      # some ingresses do not have authentication (longhorn dashboard)
      {
        src = ["lina-bh@github"]
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
        src = ["lina-bh@github"]
        dst = ["tag:k8s"]
        ip  = ["tcp:443"]
      }
    ]
    ssh = [
      # any user can SSH into their own device as any user
      {
        action = "accept"
        src    = ["autogroup:member"]
        dst    = ["autogroup:self"]
        users  = ["root", "autogroup:nonroot"]
      },
      # tailnet owner can SSH into any tagged device
      {
        action = "accept"
        src    = ["autogroup:owner"]
        dst    = ["autogroup:tagged"]
        users  = ["root", "autogroup:nonroot"]
      },
    ]
    nodeAttrs = [
      # allow mullvad to static list of devices
      {
        target = local.mullvad-devices
        attr   = ["mullvad"]
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
