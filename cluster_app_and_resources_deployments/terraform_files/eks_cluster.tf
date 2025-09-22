
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
      instance_type = "t3.medium"

      min_size     = 1
      max_size     = 2
      desired_size = 1



      # This is a labeling convention for node roles and marks the nodes.
      # It makes your setup consistent with Kubernetes standards, even though you could technically use any label (node-role=app works just fine too). 
      # Using this style helps avoid confusion and integrates smoothly with Kubernetes tooling.
      labels = {
        "node-role.kubernetes.io/app" = "true"
      }

    }

    monitoring_node = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_type = "t3.medium"

      min_size     = 1
      max_size     = 2
      desired_size = 1


      # This is a labeling convention for node roles and marks the nodes.
      # It makes your setup consistent with Kubernetes standards, even though you could technically use any label (node-role=monitoring works just fine too). 
      # Using this style helps avoid confusion and integrates smoothly with Kubernetes tooling.
      labels = {
        "node-role.kubernetes.io/monitoring" = "true"
      }

    }
    
  }


  tags = {
    Environment = "dev"
  }
}


# Additional Security Group and Ingress Rule for worker Node

resource "aws_security_group" "eks_app_worker_node_custom_sg" {
  name        = "eks_app_worker_node_http_sg"
  description = "Custom SG for HTTP/HTTPS traffic to EKS worker nodes"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Environment = "dev"
  }
}



# Outputs
output "app_worker_node_iam_role_name" {
  value = module.eks.self_managed_node_groups["app_worker_node"].iam_role_name
}


output "app_worker_node_iam_role_arn" {
  value = module.eks.self_managed_node_groups["app_worker_node"].iam_role_arn
}
