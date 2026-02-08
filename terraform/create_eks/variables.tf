variable "region" {
  description = "The name of the AWS region to use"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "The name of the key-pair to use"
  type        = string
  default     = "cloud_test"
}

variable "eks_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "my-eks-cluster"
}

variable "vpc_id" {
  description = "The id of VPC to which to attach the EKS cluster"
  type        = string
  default     = "vpc-0b8368b65cc72114a"
}

variable "vpc_subnets" {
  description = "The ids of VPC subnets to which to deploy the EKS cluster"
  type        = list(string)
  default     = ["subnet-0369fae9af5cdeadf", "subnet-0dbfad577f356ae2e"]
}

