provider "null" {}

resource "null_resource" "start_minikube" {
  provisioner "local-exec" {
    command = "minikube start"
  }
}

resource "null_resource" "wait_for_minikube" {
  depends_on = [null_resource.start_minikube]
  provisioner "local-exec" {
    command = <<EOT
      until kubectl get nodes | grep -w "Ready"; do
        echo "Αναμονή για τη συστάδα Kubernetes (Minikube)..."
        sleep 10
      done
    EOT
  }
}

resource "null_resource" "apply_manifests" {
  depends_on = [null_resource.wait_for_minikube]
  for_each   = fileset(var.path, "*.yaml")

  provisioner "local-exec" {
    command = "kubectl apply -f ${var.path}/${each.value}"
  }
}
