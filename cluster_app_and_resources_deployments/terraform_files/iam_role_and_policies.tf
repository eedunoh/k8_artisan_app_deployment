# I USED THIS RESOURCE ON HOW TO USE AND INSTALL KARPENTER + IAM ROLES - https://dhruv-mavani.medium.com/implementing-karpenter-on-eks-and-autoscaling-your-cluster-for-optimal-performance-f01a507a8f70


# A SHORT NOTE ON ODIC and IRSA
# In EKS, if you want a Kubernetes service account (e.g., for Karpenter) to assume an IAM role, you use IRSA. AWS uses the cluster’s OIDC provider for this.

# OIDC = OpenID Connect.
# It’s a standard for verifying identity over the internet. In EKS, AWS creates an OIDC provider for your cluster. This provider lets Kubernetes pods prove “I am who I say I am” to AWS.



# Difference between Normal IAM roles vs. IRSA roles

# Normal way:
# Usually, EC2 nodes (worker nodes) get an IAM role. All pods running on that node share the same AWS permissions. Problem: You give more permissions than needed. Not secure.


# IRSA (IAM Roles for Service Accounts):
# Instead of giving the node a role, you give the pod a role. You create a service account in Kubernetes, attach it to the pod. AWS uses the pod’s OIDC token to let it assume the role.
# In this case, we are giving permissions to the pod, not the node. The role is called KarpenterControllerRole — it’s meant for the Karpenter controller pod (staying in the node).




# Create a role that grant permissions to karpenter to provision ec2 instances/nodes, label them etc.

resource "aws_iam_role" "karpenter_controller_role" {
  name = "KarpenterControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # These are trust policy conditions in AWS.
          # aud (audience) = AWS STS must validate the token.
          # sub (subject) = Only this specific Kubernetes service account can use this role.
          # In plain words: “This IAM role can only be assumed by pods using the karpenter service account in the karpenter namespace, and the token must come from this cluster’s OIDC provider.”
        "${replace(module.eks.oidc_provider, "https://", "")}:aud" = "sts.amazonaws.com"
        "${replace(module.eks.oidc_provider, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })
}



# Policy to be attached to the karpenter_controller role
# Karpenter has access to carry out these actions on AWS Ec2 Instances

resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy"
  description = "Karpenter has access to carry out these actions on AWS Ec2 Instances"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "sts:AssumeRoleWithWebIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = ["ec2:TerminateInstances"]
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        }
        Resource = "*"
      },
      {
        Sid    = "PassNodeIAMRole"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = "${aws_iam_role.karpenter_node_role.arn}"
      },
      {
        Sid    = "EKSClusterEndpointLookup"
        Effect = "Allow"
        Action = ["eks:DescribeCluster"]
        Resource = "${aws_iam_role.karpenter_node_role.arn}"
      },
      {
        Sid    = "AllowScopedInstanceProfileCreationActions"
        Effect = "Allow"
        Action = ["iam:CreateInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestTag/kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region" = "${data.aws_region.current.name}"
          }
          StringLike = {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileTagActions"
        Effect = "Allow"
        Action = ["iam:TagInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region" = "${data.aws_region.current.name}"
            "aws:RequestTag/kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
            "aws:RequestTag/topology.kubernetes.io/region" = "${data.aws_region.current.name}"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowScopedInstanceProfileActions"
        Effect = "Allow"
        Action = ["iam:AddRoleToInstanceProfile","iam:RemoveRoleFromInstanceProfile","iam:DeleteInstanceProfile"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/kubernetes.io/cluster/${module.eks.cluster_name}" = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region" = "${data.aws_region.current.name}"
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
          }
        }
      },
      {
        Sid    = "AllowInstanceProfileReadActions"
        Effect = "Allow"
        Action = ["iam:GetInstanceProfile"]
        Resource = "*"
      },
      {
        Sid    = "CreateServiceLinkedRoleForEC2Spot"
        Effect = "Allow"
        Action = ["iam:CreateServiceLinkedRole"]
        Resource = "arn:aws:iam::*:role/aws-service-role/spot.amazonaws.com/AWSServiceRoleForEC2Spot"
      }
    ]
  })
}


# Attach policy to karpenter_controller IAM role. 
resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attachment" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn

  depends_on = [aws_iam_policy.karpenter_controller_policy]
}




# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# This is the role that the EC2 instances launched by Karpenter will assume. It will have access to other aws services like s3, dynamoDB and SSM
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}




# Policy to be attached to the karpenter_node role
# The application only have access to get Cognito properties from SSM and can only carryout PUT, LIST, SCAN, QUERY and UPDATE actions on S3 and DynamoDB

resource "aws_iam_policy" "ssm_dynamodb_and_s3_access" {
  name        = "ssm_read_access_and_s3_access"
  description = "Allows nodes to access SSM, DynamoDB, and S3"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
      Effect   = "Allow",
      Action   = [
        "ssm:GetParameter", 
        "ssm:GetParameters"
      ],
      "Resource": [
          "${aws_ssm_parameter.cognito_user_pool_id.arn}",
          "${aws_ssm_parameter.cognito_client_id.arn}",
          "${aws_ssm_parameter.cognito_client_secret.arn}",
          "${aws_ssm_parameter.s3_bucket_name.arn}",
          "${aws_ssm_parameter.dynamodb_name.arn}",
          "${aws_ssm_parameter.region.arn}"
      ]
    },

    {
    "Effect": "Allow",
    "Action": [
        "s3:PutObject",
        "s3:ListBucket",

        "dynamodb:PutItem",
        "dynamodb:Scan",
        "dynamodb:Query",
        "dynamodb:UpdateItem",

      ],
    "Resource": [
        "${aws_s3_bucket.artisian_app_s3_bucket.arn}",
        "${aws_s3_bucket.artisian_app_s3_bucket.arn}/*",

        "${aws_dynamodb_table.artisian_app_requests.arn}",
        "${aws_dynamodb_table.artisian_app_requests.arn}/*"
    ]
    }

    ]
  })
}




# Attach necessary policies to the karpenter node. 

# Allows the node (EC2 instance) to join and operate inside the EKS cluster
resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Allows the node to work with AWS VPC CNI plugin.
resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# This lets nodes pull container images
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# This gives the nodes permissions required to work with AWS Systems Manager (SSM) like SSM agent messaging etc.
resource "aws_iam_role_policy_attachment" "ssm_instance_core" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allows node to access other aws services like ssm, s3 and DynamoDB
resource "aws_iam_role_policy_attachment" "karpenter_node_policy_attachment" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.ssm_dynamodb_and_s3_access.arn

  depends_on = [aws_iam_policy.ssm_dynamodb_and_s3_access]
}



# Creating an iam instance profile for the karpenter node role. This will be attched to the provisioner manifests for both monitoring and app_worker nodes.
resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.karpenter_node_role.name
}



# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Create a role that grant permissions to lambda to carryout actions on SNS

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_role_for_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}



# Policy to be attached to the lambda role above.
# Lambda can send notifications via SNS

resource "aws_iam_policy" "sns_access" {
  name        = "s3_access"
  description = "Allows Lambda to access s3 buckets - least privilege"
  
  policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
                  {
                  Effect = "Allow",
                  Action = [
                      "sns:Publish"
                      ],
                  "Resource": [
                      "${aws_sns_topic.artisian_alerts.arn}"
                      ]
                  }
                  ]
        })
        }


# attach s3_access policy to the lambda iam role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.sns_access.arn
}

# This gives logs:CreateLogGroup, logs:CreateLogStream, and logs:PutLogEvents — essential for debugging lambda operations
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}





# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


output "iam_instance_profile_name" {
    value = aws_iam_instance_profile.karpenter_node_instance_profile.name
}


output "lambda_role_arn" {
  value = aws_iam_role.iam_for_lambda.arn
}



# Something to note when defining policies;   "Effect": "Allow"  OR  Effect = "Allow" can be used. 

# They can be used interchangably

# JSON uses colons (:) and double quotes ("") 
# WHILE 
# Terraform HCL uses equals signs (=) without quotes for keys.