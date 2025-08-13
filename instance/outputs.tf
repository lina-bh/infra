output "private_ip" {
  value = oci_core_instance.vm.private_ip
}

output "tailscale_ip" {
  value = data.tailscale_device.taildev.addresses[0]
}

output "hostname" {
  value = oci_core_instance.vm.display_name
}

output "tailscale_name" {
  value = data.tailscale_device.taildev.name
}
