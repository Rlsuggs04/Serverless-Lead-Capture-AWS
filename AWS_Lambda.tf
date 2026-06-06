# Creates the IAM role that the Lambda function will assume when it executes.
# The assume_role_policy defines the trust relationship, telling AWS that
# Lambda is allowed to assume this role.
resource "aws_iam_role" "epicreads_role" {
  name = "Epicreads_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Creates the IAM policy that grants the Lambda function permission
# to write logs to CloudWatch and send emails through SES
resource "aws_iam_policy" "epicreads_ses_policy" {
  name = "Epicreads_SES_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CloudWatchLogsBasic"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchLogsStreamEvents"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Sid      = "AllowSesSendEmail"
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# Attaches the policy to the role so the Lambda function
# inherits all the permissions defined in Epicreads_SES_policy
resource "aws_iam_role_policy_attachment" "epicreads_attachment" {
  role       = aws_iam_role.epicreads_role.name
  policy_arn = aws_iam_policy.epicreads_ses_policy.arn
}