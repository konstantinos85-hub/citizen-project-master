# Αναγνωριστικό της Εικόνας (AMI) της Βάσης Δεδομένων

output "db_ami_id" {
  description = "The ID of the created MySQL Database AMI"
  value       = aws_ami_from_instance.db_ami.id
}

# Αναγνωριστικό της Εικόνας (AMI) της Εφαρμογής Spring Boot

output "app_ami_id" {
  description = "The ID of the created Spring Boot Application AMI"
  value       = aws_ami_from_instance.app_ami.id
}


