# Make upload function ready for load in lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/${var.lambda_processing_json_name}"
  output_path = "${path.module}/${var.lambda_processing_json_zip_name}"
}

# create role for execution of lambda function
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
        "sts:AssumeRole"
        ],
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

## Attach basic CloudWatch logging policy
#resource "aws_iam_policy_attachment" "lambda_logs" {
#  name       = "lambda_logs"
#  roles      = [aws_iam_role.lambda_exec.name]
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#}

# create role lambda function to access dynamodb
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb-access"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.table_data.arn
    }]
  })
}

resource "aws_iam_role_policy" "lambda_publish_sns" {
  name = "lambda_publish_sns"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sns:Publish",
      Resource = aws_sns_topic.sns_topic_email.arn  # Or use "*" if testing
    }]
  })
}


# create lambda function
resource "aws_lambda_function" "processing_json" {
  function_name = "processing_json"
  filename      = "${path.module}/${var.lambda_processing_json_zip_name}"
  handler       = "processing_json.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("${var.lambda_processing_json_zip_name}")
  timeout       = 10

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.sns_topic_email.arn
      TABLE_NAME = aws_dynamodb_table.table_data.name
    }
  }
}

# Create API Gateway to trigger the Lambda function
resource "aws_apigatewayv2_api" "api" {
  name          = "api-gateway"
  protocol_type = "HTTP"
}

# Create an integration between the API Gateway and the Lambda function
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.processing_json.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# Create a route in the API Gateway that maps to the Lambda function
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /submit"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Create a stage for the API Gateway
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processing_json.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

