# main.tf - Κύρια Μονάδα

# -----------------------------------------------------------------------------
# Μέρος Ι: Provider Configuration & Subnet Tagging (Σχήμα 14)
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

# Ετικετάρισμα των δημόσιων υποδικτύων για χρήση από την υπηρεσία ELB
resource "aws_ec2_tag" "elb_tag" {
  count       = length(var.vpc_subnets)
  resource_id = var.vpc_subnets[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# Ετικετάρισμα των δημόσιων υποδικτύων για κοινή χρήση στη συστάδα EKS
resource "aws_ec2_tag" "cluster_shared_tag" {
  count       = length(var.vpc_subnets)
  resource_id = var.vpc_subnets[count.index]
  key         = "kubernetes.io/cluster/${var.eks_name}"
  value       = "shared"
}

# -----------------------------------------------------------------------------
# Μέρος II: Κλήση της μονάδας EKS Cluster (Διορθωμένο)
# -----------------------------------------------------------------------------

module "eks" {
  # ΑΛΛΑΓΗ: Καλούμε το επίσημο module αντί για τοπικό φάκελο
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_name
  cluster_version = "1.29"

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_subnets

  cluster_endpoint_public_access = true

  # Managed Node Group
  eks_managed_node_groups = {
    v3 = {
      instance_types = ["c7i-flex.large"]
      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  # Δικαιώματα διαχειριστή
  enable_cluster_creator_admin_permissions = true

  tags = {
    Project     = "CitizenAppEKS"
    Environment = "Development"
  }
}


# -----------------------------------------------------------------------------
# Μέρος III: Διαμόρφωση Providers & Κλήση Υπομονάδων (Σχήμα 16)
# -----------------------------------------------------------------------------

# Λήψη token αυθεντικοποίησης (data object)
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  # Προσθήκη του '=' πριν την αγκύλη
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}





# terraform/create_eks/main.tf

module "add_ons" {
  source       = "./modules/add_ons"
  cluster_name = module.eks.cluster_name
  
  # ΔΙΟΡΘΩΣΗ: Χρήση των σωστών ονομάτων (αριστερά) που ορίζει το variables.tf του module
  oidc_url     = module.eks.cluster_oidc_issuer_url 
  oidc_arn     = module.eks.oidc_provider_arn
  
  vpc_id       = var.vpc_id
  region       = var.region

  depends_on = [module.eks, aws_ec2_tag.elb_tag, aws_ec2_tag.cluster_shared_tag]
}


# Κλήση της υπομονάδας 'app'
module "app" {
  source = "./modules/app"
  
  # Εξάρτηση: εκτελείται μετά την εγκατάσταση των add-ons (EBS, NLB controller)
  depends_on = [module.add_ons]
}
