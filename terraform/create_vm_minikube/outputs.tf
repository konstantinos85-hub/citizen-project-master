output "instance_public_ip" {
  description = "Η δημόσια IP της εικονικής μηχανής"
  value       = aws_instance.minikube.public_ip
}

output "instance_id" {
  description = "Το ID της εικονικής μηχανής"
  value       = aws_instance.minikube.id
}

