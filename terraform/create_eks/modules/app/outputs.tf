# modules/app/outputs.tf

output "load_balancer_hostname" {
  description = "Το DNS του Load Balancer από το citizen-service-eks.yaml"
  # Ψάχνουμε μέσα στα manifests να βρούμε αυτό που έχει το hostname
  value = try(
    [for m in kubernetes_manifest.app_manifests : m.manifest.status.loadBalancer.ingress[0].hostname if can(m.manifest.status.loadBalancer.ingress[0].hostname)][0],
    "Pending..."
  )
}

output "app_namespace" {
  description = "Το namespace της εφαρμογής"
  # Παίρνουμε το namespace από το πρώτο τυχαίο αρχείο της λίστας
  value = try(values(kubernetes_manifest.app_manifests)[0].manifest.metadata.namespace, "default")
}
