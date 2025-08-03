# create topic for emails
resource "aws_sns_topic" "sns_topic_email" {
  name = var.sns_topic_name
}
resource "aws_sns_topic_subscription" "email_subscription_ec2" {
  topic_arn = aws_sns_topic.sns_topic_email.arn
  protocol  = "email"
#  endpoint  = "hristo.zhelev@yahoo.com"
  endpoint  = "metodil@hotmail.com"
}
