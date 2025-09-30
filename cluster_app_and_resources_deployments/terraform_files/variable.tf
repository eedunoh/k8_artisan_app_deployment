variable "region" {
  default = "eu-north-1"
  description = "aws region"
  type = string
}

variable "vpc_name" {
    default = "artisian_app_vpc"
    description = "aws vpc name"
    type = string
  
}

variable "eks_cluster_name" {
  default = "artisian_app_cluster"
  description = "app eks cluster name"
  type = string
}


variable "admin_email" {
  default = "eedunoh@gmail.com"
  description = "administrator email"
  type = string
}

variable "user_pool_name" {
  default = "artisian_app_user_pool"
  description = "cognito user pool name"
  type = string
}


variable "user_pool_client_name" {
    default = "my-artisian-app"
    description = "my user pool client name"
    type = string
}

variable "s3_bucket_name" {
    default = "artisian-app-s3-bucket"
    description = "s3 bucket for my artisian app"
    type = string
}


variable "dynamodb_name" {
    default = "artisian_app_requests"
    description = "artisian app dynamodb storage name"
    type = string
}

variable "lambda_function_name" {
    default = "artisian_app_lambda_function"
    description = "lambda function of the artisian app"
    type = string
}

variable "sns_name" {
    default = "artisian_app_sns"
    description = "sns notification for artisian app"
    type = string
}

variable "karpenter_version" {
  default = "v0.33.0"
  type = string
}