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
