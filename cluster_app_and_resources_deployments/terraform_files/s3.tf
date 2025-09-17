locals {
  app_worker_node_arn = module.eks.self_managed_node_groups["app_worker_node"].iam_role_arn
}

resource "aws_s3_bucket" "artisian_app_s3_bucket" {
    bucket = var.s3_bucket_name
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.artisian_app_s3_bucket.id

  topic {
    id        = "s3-object-created"
    topic_arn = aws_sns_topic.artisian_alerts.arn
    events    = ["s3:ObjectCreated:*"] # Example: Notify on all object creation events
  }
  # Note: S3 buckets only support a single notification configuration resource.
  # All desired event types and destinations should be configured within this single resource.

  
  depends_on = [aws_sns_topic_policy.allow_s3]

}


output "s3_bucket_id" {
  value = aws_s3_bucket.artisian_app_s3_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.artisian_app_s3_bucket.arn
}