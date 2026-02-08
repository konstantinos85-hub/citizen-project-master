# modules/add_ons/main.tf

# --- Μέρος Ι: Load Balancer Controller IAM ---
data "aws_iam_policy_document" "lb_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller_role" {
  name               = "eks-lb-controller-role-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.lb_assume_role_policy.json
}

resource "aws_iam_policy" "lb_controller_policy" {
  name   = "eks-lb-controller-policy-${var.cluster_name}"
  # ΔΙΟΡΘΩΣΗ: Χρήση του δικού σου ονόματος αρχείου
  policy = file("${path.module}/policies/lb_policy.json") 
}

resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  role       = aws_iam_role.lb_controller_role.name
  policy_arn = aws_iam_policy.lb_controller_policy.arn
}


resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com" = aws_iam_role.lb_controller_role.arn
    }
  }
}

# --- Μέρος ΙΙ: Helm Releases ---
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.12.0"
  
  # ΔΙΟΡΘΩΣΗ: Χρήση = για το set
  set = [{
    name  = "installCRDs"
    value = "true"
  }]
}


resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    }
  ]

  depends_on = [helm_release.cert_manager, kubernetes_service_account_v1.aws_load_balancer_controller]
}

# --- Μέρος ΙΙΙ: EBS CSI Driver ---
data "aws_iam_policy_document" "ebs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_role" {
  name               = "eks-ebs-csi-driver-role-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.ebs_assume_role_policy.json
}

# ΔΙΟΡΘΩΣΗ: Ονομάζουμε το resource σωστά για να το βρει το attachment
resource "aws_iam_policy" "ebs_csi_policy" {
  name   = "eks-ebs-csi-policy-${var.cluster_name}"
  # Βεβαιώσου ότι το αρχείο σου λέγεται ebs_csi_policy.json στον φάκελο policies
  policy = file("${path.module}/policies/ebs_csi_policy.json")
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}
