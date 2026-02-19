resource "tailscale_oauth_client" "k8s_operator" {
  scopes      = ["devices:core", "auth_keys", "services"]
  tags        = ["tag:k8s-operator"]
  description = "oke"
}

resource "oci_vault_secret" "tailscale_operator" {
  compartment_id = oci_kms_vault.vault.compartment_id
  vault_id       = oci_kms_vault.vault.id
  key_id         = oci_kms_key.primary.id
  secret_name    = "tailscale_operator"
  secret_content {
    content = base64encode(jsonencode({
      client_id     = tailscale_oauth_client.k8s_operator.id
      client_secret = tailscale_oauth_client.k8s_operator.key
    }))
    content_type = "BASE64"
  }
}


resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
  }
}

resource "kubernetes_manifest" "externalsecret_operator-oauth" {
  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      namespace = kubernetes_namespace_v1.tailscale.metadata[0].name
      name      = "operator-oauth"
    }
    spec = {
      secretStoreRef = {
        kind = kubernetes_manifest.clustersecretstore_oci.manifest.kind
        name = kubernetes_manifest.clustersecretstore_oci.manifest.metadata.name
      }
      target = {
        name = "operator-oauth"
      }
      dataFrom = [
        {
          extract = {
            key = oci_vault_secret.tailscale_operator.secret_name
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "helmrepository_tailscale" {
  depends_on = [kubernetes_manifest.fluxinstance]

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
      name      = "tailscale"
    }
    spec = {
      url = "https://pkgs.tailscale.com/helmcharts"
    }
  }
}

resource "kubernetes_manifest" "helmrelease_tailscale-operator" {
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      namespace = kubernetes_manifest.helmrepository_tailscale.manifest.metadata.namespace
      name      = "tailscale-operator"
    }
    spec = {
      interval = var.helm_interval
      chart = {
        spec = {
          chart = "tailscale-operator"
          sourceRef = {
            kind = kubernetes_manifest.helmrepository_tailscale.manifest.kind
            name = kubernetes_manifest.helmrepository_tailscale.manifest.metadata.name
          }
        }
      }
      releaseName     = "tailscale-operator"
      targetNamespace = kubernetes_namespace_v1.tailscale.metadata[0].name
      values = {
        operatorConfig = {
          image = {
            repository = "ghcr.io/tailscale/k8s-operator"
          }
          hostname = "oke"
        }
        proxyConfig = {
          image = {
            repository = "ghcr.io/tailscale/tailscale"
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "proxygroup_oke-ingress" {
  depends_on = [kubernetes_manifest.helmrelease_tailscale-operator]

  manifest = {
    apiVersion = "tailscale.com/v1alpha1"
    kind       = "ProxyGroup"
    metadata = {
      name = "oke-ingress"
    }
    spec = {
      type     = "ingress"
      replicas = 1
    }
  }
}
