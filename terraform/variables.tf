variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "value of the region where the resources will be created"
}

#variable "dynamodb_table_name" {
#  type        = string
#  default     = "aws-ess-2025-upload-table"
#  description = "The name of the DynamoDB table to create"
#
#}
#
variable "lambda_processing_json_name" {
  type        = string
  default     = "processing_json.py"
  description = "The name of the Lambda upload"
}
variable "lambda_processing_json_zip_name" {
  type        = string
  default     = "lambda__processing_json.zip"
  description = "The zip name for the Lambda upload function"
}

variable "sns_topic_name" {
  type        = string
  default     = "aws-ess-2025-sns-topic"
  description = "The name of the SNS topic to create for email notifications"
}