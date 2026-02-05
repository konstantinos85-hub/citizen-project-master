# 1. Περιοχή στο νέφος της AWS
variable "aws_region" {
  description = "Η περιοχή (region) της AWS όπου θα δημιουργηθεί η υποδομή"
  type        = string
  default     = "us-west-2"
}

# 2. Όνομα ζεύγους κλειδιών
variable "key_name" {
  description = "Το όνομα του ζεύγους κλειδιών (key pair) για τη σύνδεση μέσω SSH"
  type        = string
  default     = "cloud.test"
}

# 3. Τύπος στιγμιότυπου εικονικής μηχανής
variable "instance_type" {
  description = "Ο τύπος του στιγμιότυπου (instance type) της εικονικής μηχανής"
  type        = string
  default     = "t2.micro"
}

# 4. Αναγνωριστικό εικόνας AMI
variable "ami" {
  description = "Το ID της εικόνας AMI (Amazon Machine Image) για το ΛΣ Ubuntu"
  type        = string
  default     = "ami-0efcece6bed30fd98"
}

# 5. Μονοπάτι προς τα αρχεία YAML
variable "path" {
  description = "Το μονοπάτι προς τον φάκελο όπου υπάρχουν τα αρχεία YAML της εφαρμογής"
  type        = string
  default     = "../../yaml"
}
