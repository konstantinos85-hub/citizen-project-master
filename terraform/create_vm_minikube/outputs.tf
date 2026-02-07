output "instance_public_ip" {
  description = "Η δημόσια IP της εικονικής μηχανής"
  value       = aws_instance.minikube.public_ip
}

output "application_url" {
  description = "Το URL για την πρόσβαση στην εφαρμογή (θύρα 8089)"
  value       = "http://${aws_instance.minikube.public_ip}:8089"
}

output "instance_id" {
  description = "Το ID της εικονικής μηχανής"
  value       = aws_instance.minikube.id
}
