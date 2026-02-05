# 1. IP διεύθυνση του στιγμιοτύπου
output "instance_public_ip" {
  description = "Η δημόσια IP διεύθυνση του στιγμιοτύπου εικονικής μηχανής που δημιουργήθηκε"
  value       = aws_instance.minikube_server.public_ip
}

# 2. Αναγνωριστικό του στιγμιοτύπου
output "instance_id" {
  description = "Το μοναδικό αναγνωριστικό (ID) του στιγμιοτύπου εικονικής μηχανής στο AWS"
  value       = aws_instance.minikube_server.id
}
