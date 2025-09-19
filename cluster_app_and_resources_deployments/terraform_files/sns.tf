resource "aws_sns_topic" "artisian_alerts" {
  name = var.sns_name
}


resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.artisian_alerts.arn
  protocol  = "email"
  endpoint  = var.admin_email # Admin email address

    # Add a filter policy to clean up the notification
    filter_policy = jsonencode({
    eventName = ["ObjectCreated:Put"] # Only send emails for PUT operations
    })
}

output "sns_arn" {
  value = aws_sns_topic.artisian_alerts.arn
}