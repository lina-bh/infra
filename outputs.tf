output "k3s_token" {
  sensitive = true
  value     = random_password.k3s_token.result
}

output "server_host" {
  value = try(module.instance[0].tailscale_ip, "")
}

output "oci_os_ns" {
  value = data.oci_objectstorage_namespace.ns.namespace
}

output "oci_os_s3_endpoint" {
  value = "https://${data.oci_objectstorage_namespace.ns.namespace}.compat.objectstorage.uk-london-1.oraclecloud.com"
}
