variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "value of the region where the resources will be created"
}

variable "dynamodb_table_name" {
  type        = string
  default     = "aws-ess-2025-processing-table"
  description = "The name of the DynamoDB table to create"

}

variable "gsi_name" {
  type        = string
  default     = "buyer-name-index"
  description = "The name of the Global Secondary Index for the DynamoDB table"
}

variable "gsi_hash_key" {
  type        = string
  default     = "buyer"
  description = "The hash key for the Global Secondary Index"
}


variable "lambda_processing_json_name" {
  type        = string
  default     = "processing_json.py"
  description = "The name of the Lambda processing_json function"
}
variable "lambda_processing_json_zip_name" {
  type        = string
  default     = "lambda__processing_json.zip"
  description = "The zip name for the Lambda processing_json function"
}

variable "lambda_delete_and_notify_name" {
  type        = string
  default     = "delete_and_notify.py"
  description = "The name of the Lambda delete_and_notify function"
}
variable "lambda_delete_and_notify_zip_name" {
  type        = string
  default     = "lambda__delete_and_notify.zip"
  description = "The zip name for the Lambda delete_and_notify function"
}


variable "sns_topic_name" {
  type        = string
  default     = "aws-ess-2025-sns-topic"
  description = "The name of the SNS topic to create for email notifications"
}