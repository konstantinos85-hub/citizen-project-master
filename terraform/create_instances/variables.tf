# --- Περιοχή και Στιγμιότυπα ---
variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-west-2"
}

variable "instance_type_app" {
  description = "EC2 instance type for the Spring Boot application"
  type        = string
  default     = "t3.micro"
}

variable "instance_type_db" {
  description = "EC2 instance type for the Register DB"
  type        = string
  default     = "t3.micro"
}

# --- Δικτυακές Ρυθμίσεις (Με τα δικά σας IDs) ---
variable "vpc_id" {
  description = "VPC Id for the infrastructure"
  type        = string
  default     = "vpc-0353de65de75ebb17"
}

variable "subnets" {
  description = "Subnets for the load balancer"
  type        = list(string)
  default     = ["subnet-0646c7068db1303ef", "subnet-0d9000c4c4830e111"]
}

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = "cloud.test"
}

# --- Μεταβλητές Βάσης Δεδομένων ---
variable "db_user" {
  description = "Username for the MySQL database"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Password for the MySQL database"
  type        = string
  default     = "citizen1"
  sensitive   = true 
}

variable "db_name" {
  description = "Name for the MySQL database"
  type        = string
  default     = "citizen"
}

# --- Ρυθμίσεις Εφαρμογής ---
variable "jar_name" {
  description = "The name of the app jar file"
  type        = string
  default     = "citizen-service-0.0.1-SNAPSHOT"
}
