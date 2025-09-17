resource "aws_sns_topic" "artisian_alerts" {
  name = var.sns_name
}

resource "aws_sns_topic_policy" "allow_s3" {
  arn = aws_sns_topic.artisian_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.artisian_alerts.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.artisian_app_s3_bucket.arn
          }
        }
      }
    ]
  })
}


resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.artisian_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email # Admin email address
}

output "sns_arn" {
  value = aws_sns_topic.artisian_alerts.arn
}