locals {
  archs = toset(["x86_64", "aarch64"])

  shape = tomap({
    aarch64 = "VM.Standard.A1.Flex"
    x86_64  = "VM.Standard.E2.1.Micro"
  })

  availability_domains = {
    "1" = data.oci_identity_availability_domains.ad.availability_domains[0].name
    "3" = data.oci_identity_availability_domains.ad.availability_domains[2].name
  }

  # image_ocids = {
  #   x86_64  = oci_core_image.alpine["x86_64"].id
  #   aarch64 = oci_core_image.alpine["aarch64"].id
  # }

  security_list_protocol = {
    ICMP    = "1"
    TCP     = "6"
    UDP     = "17"
    ICMPSIX = "58"
  }
}
