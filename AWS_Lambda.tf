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

# Zips the Lambda function source code from the lambda/ folder
# so Terraform can upload it to AWS as a deployment package
data "archive_file" "epicreads_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

# Creates the Lambda function using the zipped source code,
# attaches the IAM role, and passes the SES email addresses
# Has environment variables so the function can reference them at runtime
resource "aws_lambda_function" "epicreads_contactus" {
  filename         = data.archive_file.epicreads_lambda.output_path         # Path to the zipped Lambda function code
  function_name    = "epicreads_contactus"                                  #Name of the Lambda function in AWS
  role             = aws_iam_role.epicreads_role.arn                        # ARN of the IAM role that the Lambda function will assume
  handler          = "index.handler"                                        # Tell Lambda which file and function to run when Lambda is triggered. In this case, it looks for the handler function in the index.mjs file.
  runtime          = "nodejs20.x"                                           # Tells AWS to run in a Node.js 20.x environment, which is compatible with the code in index.mjs
  source_code_hash = data.archive_file.epicreads_lambda.output_base64sha256 # A base64-encoded SHA256 hash of the zipped Lambda function code. This is used by Terraform to detect changes in the code and trigger updates to the Lambda function when the code changes.

  environment { #Passing sensitiuve information as environment variables so they are not hardcoded in the Lambda function code
    variables = {
      RECEIVER_EMAIL = var.email1
      SENDER_EMAIL   = var.email2
    }
  }

  tags = {
    Name = "epicreads-contactus"
  }
}
