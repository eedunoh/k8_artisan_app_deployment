resource "aws_ssm_parameter" "cognito_user_pool_id" {
  name  = "cognito_user_pool_id"
  type  = "String"
  value = aws_cognito_user_pool.my_user_pool.id
}

resource "aws_ssm_parameter" "cognito_client_id" {
  name  = "cognito_client_id"
  type  = "String"
  value = aws_cognito_user_pool_client.my_user_pool_client.id
}

resource "aws_ssm_parameter" "cognito_client_secret" {
  name  = "cognito_client_secret"
  type  = "String" # Secure value!
  value = aws_cognito_user_pool_client.my_user_pool_client.client_secret
}


resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "s3_bucket_name"
  type  = "String"
  value = var.s3_bucket_name
}

resource "aws_ssm_parameter" "dynamodb_name" {
  name  = "dynamodb_name"
  type  = "String"
  value = var.dynamodb_name
}


resource "aws_ssm_parameter" "region" {
  name  = "region"
  type  = "String"
  value = var.region
}