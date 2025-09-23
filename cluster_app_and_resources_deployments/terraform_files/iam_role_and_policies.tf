

# Something to note when defining policies;   "Effect": "Allow"  OR  Effect = "Allow" can be used. 

# They can be used interchangably

# JSON uses colons (:) and double quotes ("") 
# WHILE 
# Terraform HCL uses equals signs (=) without quotes for keys.


# Policy to be attached to the app_worker_node role auto-created by the eks module
# The application only have access to get Cognito properties from SSM and can only carryout PUT, LIST, SCAN, QUERY and UPDATE actions on S3 and DynamoDB

resource "aws_iam_policy" "ssm_dynamodb_and_s3_access" {
  name        = "ssm_read_access_and_s3_access"
  description = "Allows app worker nodes to access SSM, DynamoDB, and S3"
  
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


# attach the policy to the app worker node role
resource "aws_iam_role_policy_attachment" "app_worker_node_policy_attachment" {
  role       = module.eks.self_managed_node_groups["app_worker_node"].iam_role_name
  policy_arn = aws_iam_policy.ssm_dynamodb_and_s3_access.arn

  depends_on = [aws_iam_policy.ssm_dynamodb_and_s3_access]
}




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



# The PVC for Prometheus is stuck in Pending because the EBS CSI driver is trying to provision a volume in AWS, but the EC2 role of the monitoring node does not have permission to create EBS volumes.
# This policy is needed to address this situation.

resource "aws_iam_policy" "ebs_csi_operation" {
  name        = "ebs_csi_operation"
  description = "Allows EBS CSI driver provision volume in AWS - to be used by prometheus"
  
  policy = jsonencode({
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "ec2:CreateVolume",
                      "ec2:AttachVolume",
                      "ec2:DeleteVolume",
                      "ec2:DescribeVolumes",
                      "ec2:DescribeVolumeStatus",
                      "ec2:DetachVolume",
                      "ec2:ModifyVolume",
                      "ec2:DescribeInstances",
                      "ec2:DescribeTags",
                      "ec2:CreateTags",
                      "ec2:DeleteTags"
                  ],
                  "Resource": "*"
              }
          ]
      })
        }


# attach the policy to the app monitoring and app_worker node roles
# Kubernetes could provision the PVC using a different node’s IAM role. This comes down to how WaitForFirstConsumer and CSI dynamic provisioning work in EKS. 
# So its best to attch the policy to both node roles.
resource "aws_iam_role_policy_attachment" "ebs_csi_operation_policy_attachment_node1" {
  role       = module.eks.self_managed_node_groups["monitoring_node"].iam_role_name
  policy_arn = aws_iam_policy.ebs_csi_operation.arn

  depends_on = [aws_iam_policy.ebs_csi_operation]
}

resource "aws_iam_role_policy_attachment" "ebs_csi_operation_policy_attachment_node2" {
  role       = module.eks.self_managed_node_groups["app_worker_node"].iam_role_name
  policy_arn = aws_iam_policy.ebs_csi_operation.arn

  depends_on = [aws_iam_policy.ebs_csi_operation]
}












output "lambda_role_arn" {
  value = aws_iam_role.iam_for_lambda.arn
}