resource "tailscale_oauth_client" "k8s_operator" {
  scopes      = ["devices:core", "auth_keys", "services"]
  tags        = ["tag:k8s-operator"]
  description = "oke"
}

resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_secret_v1" "operator_oauth" {
  metadata {
    namespace = kubernetes_namespace_v1.tailscale.metadata[0].name
    name = "operator-oauth"
  }

  data = {
    client_id = tailscale_oauth_client.k8s_operator.id
    client_secret = tailscale_oauth_client.k8s_operator.key
  }

  wait_for_service_account_token = false
}
