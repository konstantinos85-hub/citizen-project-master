variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "key_name" {
  description = "Όνομα του SSH key pair στο AWS"
  type        = string
  default     = "cloud.test"
}

variable "private_key_path" {
  description = "Το τοπικό μονοπάτι προς το .pem αρχείο"
  type        = string
  default     = "./cloud.test.pem" # Βεβαιώσου ότι το αρχείο είναι στον ίδιο φάκελο
}

variable "instance_type" {
  description = "Minikube requires at least 2 vCPUs (t3.medium)"
  type        = string
  default     = "t3.medium" 
}

variable "ami" {
  description = "Ubuntu 24.04 LTS AMI"
  type        = string
  default     = "ami-0aff18ec83b712f05" 
}

variable "github_repo" {
  description = "Το URL του repository σου"
  type        = string
  default     = "https://github.com/konstantinos85-hub/citizen-project-master.git"
}
