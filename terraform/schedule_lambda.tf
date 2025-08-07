# Create Schedular to start every minute Lambda Function
# for check 30 minutes old items and Deleting deleting them
# then Notify via SNS

# Create CloudWatch Event Schedular to trigger Lambda every minute
resource "aws_cloudwatch_event_rule" "every_minute" {
  name                = "run-every-minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.every_minute.name
  target_id = "lambda"
  arn       = aws_lambda_function.delete_and_notify.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_and_notify.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minute.arn
}

# Create Lambda function to delete old items and notify via SNS
# First roles and policies
resource "aws_iam_role" "lambda_exec_delete_and_notify" {
  name = "lambda_exec_delete_and_notify"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_delete_and_notify_logs" {
  role       = aws_iam_role.lambda_exec_delete_and_notify.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy" "lambda_delete_and_notify_publish_sns" {
  name = "lambda_delete_and_notify_publish_sns"
  role = aws_iam_role.lambda_exec_delete_and_notify.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "sns:Publish",
      Resource = aws_sns_topic.sns_topic_email.arn # Or use "*" if testing
    }]
  })
}

resource "aws_iam_role_policy" "lambda_delete_and_notify_custom" {
  name = "lambda-dynamodb-email"
  role = aws_iam_role.lambda_exec_delete_and_notify.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Scan",
          "dynamodb:DeleteItem"
        ],
        Resource = aws_dynamodb_table.table_data.arn
      }
      #      ,
      #      {
      #        Effect = "Allow",
      #        Action = [
      #          "ses:SendEmail",
      #          "ses:SendRawEmail"
      #        ],
      #        Resource = "*"
      #      }
    ]
  })
}

# Make upload function ready for load in lambda
data "archive_file" "lambda_delete_and_notify_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/${var.lambda_delete_and_notify_name}"
  output_path = "${path.module}/${var.lambda_delete_and_notify_zip_name}"
}


# Create delete and notify Lambda function
resource "aws_lambda_function" "delete_and_notify" {
  filename         = var.lambda_delete_and_notify_zip_name # Upload your zip
  function_name    = "delete_and_notify"
  handler          = "delete_and_notify.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_delete_and_notify.arn
  source_code_hash = filebase64sha256("${var.lambda_delete_and_notify_zip_name}")

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.sns_topic_email.arn
      TABLE_NAME    = aws_dynamodb_table.table_data.name
    }
  }
}
