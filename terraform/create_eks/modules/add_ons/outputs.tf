# modules/add_ons/outputs.tf

output "lb_controller_role_arn" {
  description = "Το ARN του IAM Role για τον Load Balancer Controller"
  value       = aws_iam_role.lb_controller_role.arn
}

output "ebs_csi_role_arn" {
  description = "Το ARN του IAM Role για τον EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_role.arn
}

output "status" {
  description = "Status ένδειξη ότι τα add-ons ολοκληρώθηκαν"
  value       = "ready"
  depends_on = [
    helm_release.aws_lb_controller,
    aws_eks_addon.ebs_csi_driver
  ]
}
