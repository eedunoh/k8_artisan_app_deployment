
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

    kubernetes_utilities_node = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_type = "m5.xlarge"

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  tags = {
    Environment = "dev"
  }
}






# Outputs

data "aws_caller_identity" "current" {}   
# Purpose: Gets information about the AWS account and caller (the credentials you’re using to run Terraform).
# Key attributes: account_id → Your AWS account ID, arn → The ARN of the caller and user_id → The unique ID of the caller


output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}



data "aws_region" "current" {}
# Purpose: Returns the AWS region Terraform is operating in (from your provider or environment).
# Key attribute: name → The AWS region, e.g., eu-north-1


output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_region" {
  value = var.region
}





# OIDC = OpenID Connect.
# It’s a standard for verifying identity over the internet. In EKS, AWS creates an OIDC provider for your cluster. This provider lets Kubernetes pods prove “I am who I say I am” to AWS.

output "eks_oidc_provider_arn" {              # this is similar to OIDC_ENDPOINT. Since we are using the terraform-aws-modules/eks/aws module, it already exposes this as outputs.
  value = module.eks.oidc_provider_arn
}