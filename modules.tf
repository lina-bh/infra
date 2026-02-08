# module "instance" {
#   source = "./instance"
#   count  = 0
#
#   compartment_ocid     = oci_core_subnet.sn.compartment_id
#   subnet_ocid          = oci_core_subnet.sn.id
#   availability_domains = local.availability_domains
#
#   name       = each.key
#   arch       = each.value.arch
#   image_ocid = oci_core_image.alpine[each.value.arch].id
#
#   ansible_groups = [each.key == "server" ? "server" : "worker"]
# }
