variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "vpc_id" {
  description = "The id of VPC to which to attach the EKS cluster"
  type        = string
}

variable "oidc_url" {
  description = "The URL of OIDC"
  type        = string
}

variable "oidc_arn" {
  description = "The ARN identifier of OIDC"
  type        = string
}

variable "region" {
  description = "The name of the AWS region to use"
  type        = string
}
