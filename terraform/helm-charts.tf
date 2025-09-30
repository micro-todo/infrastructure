provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.microtodo_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.microtodo_eks_cluster.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.microtodo_eks_cluster.name,
        "--region",
        local.region
      ]
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4"
  timeout    = 900
  wait       = true

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.microtodo_eks_cluster.name
    },
    {
      name  = "region"
      value = local.region
    },
    {
      name  = "vpcId"
      value = aws_vpc.microtodo_vpc.id
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.aws_load_balancer_controller.arn
    }
  ]

  depends_on = [
    aws_iam_role_policy.aws_load_balancer_controller_policy,
    aws_eks_access_policy_association.admin_access_policy,
    aws_eks_access_policy_association.root_admin_access_policy,
    aws_eks_node_group.microtodo_eks_node_group
  ]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.5.7"

  # Optional: Expose ArgoCD server via LoadBalancer for easy access
  # In production, you'd use Ingress instead
  # set = [
  #   {
  #     name  = "server.service.type"
  #     value = "LoadBalancer"
  #   }
  # ]

  depends_on = [
    aws_eks_node_group.microtodo_eks_node_group,
    helm_release.aws_load_balancer_controller
  ]
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets-system"
  create_namespace = true
  version          = "0.20.1"

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.external_secrets_role.arn
    }
  ]

  depends_on = [
    aws_eks_node_group.microtodo_eks_node_group,
    aws_iam_role_policy_attachment.external_secrets_policy_attach,
    helm_release.aws_load_balancer_controller
  ]
}
