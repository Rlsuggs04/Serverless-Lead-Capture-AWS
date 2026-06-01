# Serverless-Lead-Capture-AWS
Serverless lead capture platform built on AWS. Hosts a static site via S3 + CloudFront (CDN for global performance), routes traffic through Route 53 with HTTPS enforced via ACM, captures leads through API Gateway + Lambda, persists data in DynamoDB, and triggers email notifications via SES. IaC managed with Terraform.
