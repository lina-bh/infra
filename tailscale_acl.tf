# https://tailscale.com/kb/1337/acl-syntax
resource "tailscale_acl" "acl" {
  acl = jsonencode({
    tagOwners = {
      "tag:oci" : [],
      "tag:quadlet" : ["autogroup:owner"],
      "tag:svc" : [],
      "tag:server" : ["autogroup:owner"],
      "tag:exit-node" : ["autogroup:owner"],
    },
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
      # my devices can use kde connect, sunshine and ssh on 2222
      {
        src = ["autogroup:owner"]
        dst = ["autogroup:self"]
        ip  = ["1714-1746", "tcp:47984-48010", "udp:47998-48000", "tcp:2222"]
      },
      # i can connect to all services HTTPS
      {
        src = ["autogroup:owner"]
        dst = ["tag:svc", "tag:server"]
        ip  = ["tcp:443"]
      },
      {
        src = ["autogroup:member"]
        dst = ["autogroup:internet"]
        ip  = ["*"]
      }
    ]
    ssh = [
      # anyone can ssh into their own devices
      {
        action = "check"
        src    = ["autogroup:member"]
        dst    = ["autogroup:self"]
        users  = ["root", "autogroup:nonroot"]
      },
      # i can connect to oci without confirmation for ansible
      {
        action = "accept"
        src    = ["autogroup:owner"]
        dst    = ["tag:oci"]
        users  = ["root"]
      }
    ]
    groups = {
      "group:mullvad" : ["lina-bh@github"],
    }
    nodeAttrs = [
      # allow mullvad to my devices
      {
        target = ["group:mullvad"]
        attr   = ["mullvad"]
      },
    ],
    autoApprovers = {
      services : {
        "tag:quadlet" : ["tag:svc"],
        "tag:oci" : ["tag:svc"],
        "tag:server" : ["tag:server"]
      },
      exitNode = ["tag:exit-node"]
    }
  })
}
