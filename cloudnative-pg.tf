resource "kubernetes_manifest" "helmrepository_cloudnative-pg" {
  depends_on = [kubernetes_manifest.fluxinstance]

  manifest = {
    apiVersion = "source.toolkit.fluxcd.io/v1"
    kind       = "HelmRepository"
    metadata = {
      namespace = kubernetes_namespace_v1.flux-system.metadata[0].name
      name      = "cloudnative-pg"
    }
    spec = {
      url = "https://cloudnative-pg.github.io/charts"
    }
  }
}

resource "kubernetes_manifest" "helmrelease_cloudnative-pg" {
  manifest = {
    apiVersion = "helm.toolkit.fluxcd.io/v2"
    kind       = "HelmRelease"
    metadata = {
      namespace = kubernetes_manifest.helmrepository_cloudnative-pg.manifest.metadata.namespace
      name      = "cloudnative-pg"
    }
    spec = {
      interval = var.helm_interval
      chart = {
        spec = {
          chart   = "cloudnative-pg"
          version = "0.27"
          sourceRef = {
            kind = kubernetes_manifest.helmrepository_cloudnative-pg.manifest.kind
            name = kubernetes_manifest.helmrepository_cloudnative-pg.manifest.metadata.name
          }
        }
      }
      releaseName     = "cloudnative-pg"
      targetNamespace = "cnpg-system"
      install = {
        createNamespace = true
      }
    }
  }
}
