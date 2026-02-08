# outputs.tf - Κύρια Μονάδα

output "cluster_id" {
  description = "Το αναγνωριστικό της EKS συστάδας που δημιουργήθηκε"
  value       = module.eks.cluster_id
}

output "cluster_endpoint" {
  description = "Το τελικό σημείο (endpoint) της συστάδας αυτής"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Το αναγνωριστικό της ομάδας ασφάλειας (security group id) της συστάδας"
  value       = module.eks.cluster_security_group_id
}


# outputs.tf (Root)

output "final_api_url" {
  value = "http://${module.app.load_balancer_hostname}:8089"
}
