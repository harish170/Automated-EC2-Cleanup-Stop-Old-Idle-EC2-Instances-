provider "aws" {
  region = "us-east-1"
}

########################################
# IAM ROLE FOR LAMBDA
########################################
resource "aws_iam_role" "lambda_role" {
  name = "ec2-cleanup-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

########################################
# IAM POLICY (EC2 + LOGS PERMISSIONS)
########################################
resource "aws_iam_role_policy" "lambda_policy" {
  name = "ec2-cleanup-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # EC2 permissions
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances"
        ]
        Resource = "*"
      },

      # CloudWatch logs permissions
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

########################################
# CLOUDWATCH LOG GROUP (OPTIONAL BUT GOOD)
########################################
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/ec2-cleanup"
  retention_in_days = 14
}

########################################
# LAMBDA FUNCTION
########################################
resource "aws_lambda_function" "cleanup" {

  function_name = "ec2-cleanup"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.11"

  filename         = "../lambda.zip"
  source_code_hash = filebase64sha256("../lambda.zip")

  depends_on = [aws_iam_role_policy.lambda_policy]
}

########################################
# EVENTBRIDGE RULE (SCHEDULE)
########################################
resource "aws_cloudwatch_event_rule" "daily_rule" {
  name                = "ec2-cleanup-daily-rule"
  schedule_expression = "rate(1 day)"
}

########################################
# EVENTBRIDGE TARGET (CONNECT TO LAMBDA)
########################################
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.daily_rule.name
  arn  = aws_lambda_function.cleanup.arn
}

########################################
# PERMISSION FOR EVENTBRIDGE TO CALL LAMBDA
########################################
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_rule.arn
}
