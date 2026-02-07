variable "aws_region" {
  description = "Region N. Virginia"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Όνομα του SSH key pair στο us-east-1"
  type        = string
  default     = "cloud.test"
}

variable "private_key_path" {
  description = "Το τοπικό μονοπάτι προς το .pem αρχείο"
  type        = string
  default     = "./cloud.test.pem"
}

variable "instance_type" {
  description = "Minikube needs t3.medium"
  type        = string
  default     = "t2.medium"
}

variable "ami" {
  description = "Ubuntu Server 24.04 LTS (x86) - us-east-1"
  type        = string
  default     = "ami-0b6c6ebed2801a5cb" 
}

variable "github_repo" {
  description = "Το URL του repository σου"
  type        = string
  default     = "https://github.com/konstantinos85-hub/citizen-project-master.git"
}
