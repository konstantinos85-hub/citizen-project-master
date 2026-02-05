output "minikube_status" {
  depends_on = [null_resource.apply_manifests]
  value      = "Η συστάδα Minikube εκκινήθηκε επιτυχώς και η εφαρμογή έχει διαταχθεί πλήρως!"
}
