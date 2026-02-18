resource "kubernetes_manifest" "helmrepository_longhorn" {
  depends_on = [kubernetes_manifest.fluxinstance]

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
      name      = "longhorn"
    }
    spec = {
      url = "https://charts.longhorn.io"
    }
  }
}

resource "kubernetes_manifest" "helmrelease_longhorn" {
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      namespace = kubernetes_manifest.helmrepository_longhorn.manifest.metadata.namespace
      name      = "longhorn"
    }
    spec = {
      interval = var.helm_interval
      chart = {
        spec = {
          chart   = "longhorn"
          version = "1.11"
          sourceRef = {
            kind = kubernetes_manifest.helmrepository_longhorn.manifest.kind
            name = kubernetes_manifest.helmrepository_longhorn.manifest.metadata.name
          }
        }
      }
      targetNamespace = "longhorn-system"
      install = {
        createNamespace = true
      }
      values = {
        networkPolicies = {
          enabled = true
        }
        persistence = {
          defaultClassReplicaCount = var.nodes
          reclaimPolicy            = "Retain"
        }
        defaultSettings = {
          defaultReplicaCount = var.nodes
        }
        longhornUI = {
          replicas = 1
        }
        csi = {
          attacherReplicaCount    = var.nodes
          provisionerReplicaCount = var.nodes
          resizerReplicaCount     = var.nodes
          snapshotterReplicaCount = var.nodes
        }
      }
    }
  }
}
