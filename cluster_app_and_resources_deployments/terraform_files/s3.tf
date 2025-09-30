resource "aws_s3_bucket" "artisian_app_s3_bucket" {
    bucket = var.s3_bucket_name
}


# Setup s3 event notification to trigger lambda when files are added to the s3 bucket
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.artisian_app_s3_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.artisan_app_lambda_function.arn
    events              = ["s3:ObjectCreated:*"]      # Lambda is triggered when any event is created
  }

  depends_on = [aws_lambda_permission.allow_bucket]     # Depends on the lambda invoke function (this is defined in the lambda function terraform file). It gives permission to the s3 bucket to invoke lambda
}


output "s3_bucket_id" {
  value = aws_s3_bucket.artisian_app_s3_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.artisian_app_s3_bucket.arn
}