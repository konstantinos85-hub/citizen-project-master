# Η δημόσια διεύθυνση URL για την πρόσβαση στη RESTful υπηρεσία
output "service_url" {
  description = "The URL to access your Spring Boot service"
  value       = "http://${aws_lb.app_lb.dns_name}"
}

# Η εσωτερική IP της βάσης δεδομένων (χρήσιμο για debugging)
output "db_internal_ip" {
  description = "The private IP of the database instance"
  value       = aws_instance.db.private_ip
}

# Τα αναγνωριστικά των 3 στιγμιοτύπων της εφαρμογής
output "app_instance_ids" {
  description = "IDs of the application instances"
  value       = aws_instance.app[*].id
}


