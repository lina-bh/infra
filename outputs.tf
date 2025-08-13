output "k3s_token" {
  sensitive = true
  value     = random_password.k3s_token.result
}

output "server_host" {
  value = try(module.instance[0].tailscale_ip, "")
}

output "ts_k8s_client_id" {
  sensitive = true
  value     = tailscale_oauth_client.k8s.id
}

output "ts_k8s_client_secret" {
  sensitive = true
  value     = tailscale_oauth_client.k8s.key
}
