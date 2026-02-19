resource "kubernetes_namespace_v1" "flux-system" {
  depends_on = [local_file.kubeconfig]

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }

  metadata {
    name = "flux-system"
  }
}

resource "helm_release" "flux_operator" {
  name      = "flux-operator"
  chart     = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator"
  atomic    = true
  namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
  set = [
    {
      name  = "web.enabled"
      value = "false"
    }
  ]
}

resource "kubernetes_manifest" "fluxinstance" {
  depends_on = [helm_release.flux_operator]

  manifest = {
    apiVersion = "fluxcd.controlplane.io/v1"
    kind       = "FluxInstance"
    metadata = {
      annotations = {
        "fluxcd.controlplane.io/reconcile"      = "enabled"
        "fluxcd.controlplane.io/reconcileEvery" = var.helm_interval
      }
      name      = "flux"
      namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
    }
    spec = {
      cluster = {
        networkPolicy = true
      }
      commonMetadata = {
        labels = {
          "app.kubernetes.io/name" = "flux"
        }
      }
      components = [
        "source-controller",
        "helm-controller",
      ]
      distribution = {
        registry = "ghcr.io/fluxcd"
        version  = "2.7.x"
      }
      kustomize = {
        patches = [
          {
            patch = <<-EOT
- op: replace
  path: /spec/template/spec/nodeSelector
  value:
    kubernetes.io/os: linux
- op: add
  path: /spec/template/spec/tolerations
  value:
    - key: "CriticalAddonsOnly"
      operator: "Exists"
EOT
            target = {
              kind = "Deployment"
            }
          },
        ]
      }
    }
  }
}

resource "kubernetes_namespace_v1" "external-secrets" {
  metadata {
    name = "external-secrets"
  }
}

resource "kubernetes_manifest" "helmrepository_external-secrets" {
  depends_on = [kubernetes_manifest.fluxinstance]

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
      name      = "external-secrets"
    }
    spec = {
      url = "https://charts.external-secrets.io"
    }
  }
}

resource "kubernetes_manifest" "helmrelease_external-secrets" {
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      namespace = kubernetes_manifest.helmrepository_external-secrets.manifest.metadata.namespace
      name      = "external-secrets"
    }
    spec = {
      interval = var.helm_interval
      chart = {
        spec = {
          chart = "external-secrets"
          sourceRef = {
            kind = "HelmRepository"
            name = kubernetes_manifest.helmrepository_external-secrets.manifest.metadata.name
          }
        }
      }
      targetNamespace = kubernetes_namespace_v1.external-secrets.metadata[0].name
      releaseName     = "external-secrets"
      values = {
        installCRDs = true
      }
    }
  }
}
