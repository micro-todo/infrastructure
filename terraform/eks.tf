# TODO: In a production scenario, you should create tight Security Groups for the cluster and nodes for better security.
# But for the purposes of this example, we'll stick with the defaults.

resource "aws_eks_cluster" "microtodo_eks_cluster" {
  name     = "microtodo_eks_cluster"
  version  = "1.31"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.microtodo_public_subnets["a"].id,
      aws_subnet.microtodo_public_subnets["b"].id,
      aws_subnet.microtodo_public_subnets["c"].id,
      aws_subnet.microtodo_private_subnets["a"].id,
      aws_subnet.microtodo_private_subnets["b"].id,
      aws_subnet.microtodo_private_subnets["c"].id
    ]
    endpoint_private_access = true
    # This is a dev only measure, in production you should use some kind of Bastion host or something
    endpoint_public_access = true
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Name = "microtodo_eks_cluster"
  }
}

resource "aws_eks_node_group" "microtodo_eks_node_group" {
  cluster_name    = aws_eks_cluster.microtodo_eks_cluster.name
  node_group_name = "microtodo_eks_node_group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn

  subnet_ids = [
    aws_subnet.microtodo_private_subnets["a"].id,
    aws_subnet.microtodo_private_subnets["b"].id,
    aws_subnet.microtodo_private_subnets["c"].id
  ]
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]

  tags = {
    Name = "microtodo_eks_node_group"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_eks_access_entry" "admin_access" {
  cluster_name  = aws_eks_cluster.microtodo_eks_cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_access_policy" {
  cluster_name  = aws_eks_cluster.microtodo_eks_cluster.name
  principal_arn = data.aws_caller_identity.current.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_access]
}

# You should not do this in production.
# Generally in AWS the root user should only ever be used to create the initial admin user.
resource "aws_eks_access_entry" "root_admin_access" {
  cluster_name = aws_eks_cluster.microtodo_eks_cluster.name
  # You should probably use a more specific IAM user instead of root, but for the purposes of this example, we'll use root.
  principal_arn = "arn:aws:iam::${var.aws_account_id}:root"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "root_admin_access_policy" {
  cluster_name  = aws_eks_cluster.microtodo_eks_cluster.name
  principal_arn = "arn:aws:iam::${var.aws_account_id}:root"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.root_admin_access]
}
