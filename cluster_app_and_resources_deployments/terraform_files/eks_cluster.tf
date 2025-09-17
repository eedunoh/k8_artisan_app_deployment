
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = data.aws_vpc.main.id
  subnet_ids               = data.aws_subnets.private_subnets.ids


  # EKS Managed Node Group(s)
  self_managed_node_groups = {

    app_worker_node = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }

    # In this project, I intend to integrate CI/CD and monitoring tools Github Actions/Jenkins, Prometheus and Grafan. I will spin up different servers to run these tools particularly in the private subnets.
    
  }


  tags = {
    Environment = "dev"
  }
}



output "app_worker_node_iam_role_name" {
  value = module.eks.self_managed_node_groups["app_worker_node"].iam_role_name
}


output "app_worker_node_iam_role_arn" {
  value = module.eks.self_managed_node_groups["app_worker_node"].iam_role_arn
}
