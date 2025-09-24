module "instance" {
  source = "./instance"
  count  = 3

  compartment_ocid     = oci_core_subnet.sn.compartment_id
  subnet_ocid          = oci_core_subnet.sn.id
  arch                 = count.index % 2 != 0 ? "x86_64" : "aarch64"
  image_ocids          = local.image_ocids
  availability_domains = local.availability_domains
  ansible_groups       = [count.index == 0 ? "server" : "worker"]
}
