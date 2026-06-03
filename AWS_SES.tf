# Declares the email1 variable to store the first SES verified email address
variable "email1" {
  description = "First SES verified email address"
  type        = string
}

# Declares the email2 variable to store the second SES verified email address
variable "email2" {
  description = "Second SES verified email address"
  type        = string
}

# Creates the first SES email identity and sends a verification email to email1
resource "aws_ses_email_identity" "email1" {
  email = var.email1
}

# Creates the second SES email identity and sends a verification email to email2
resource "aws_ses_email_identity" "email2" {
  email = var.email2
}