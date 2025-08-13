locals {
  shape = tomap({
    aarch64 = "VM.Standard.A1.Flex"
    x86_64  = "VM.Standard.E2.1.Micro"
  })

  availability_domains = tomap({
    aarch64 = 0
    x86_64  = 2
  })

  is_aarch64 = var.arch == "aarch64"
}
