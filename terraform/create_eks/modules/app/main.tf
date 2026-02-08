# modules/app/main.tf

resource "kubernetes_manifest" "app_manifests" {
  # Δημιουργούμε μια λίστα από όλα τα resources όλων των YAML αρχείων
  for_each = {
    for pair in flatten([
      for file in fileset("${path.root}/../../Kubernetes/eks", "*.yaml") : [
        for idx, doc in split("\n---\n", file("${path.root}/../../Kubernetes/eks/${file}")) : {
          key     = "${file}-${idx}"
          content = doc
        } if trimspace(doc) != ""
      ]
    ]) : pair.key => pair.content
  }

  manifest = yamldecode(each.value)
}


