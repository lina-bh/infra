output "k3s_token" {
  sensitive = true
  value     = random_password.k3s_token.result
}

output "server_host" {
  value = try(module.instance[0].tailscale_ip, "")
}
