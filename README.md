# Serverless Lead Capture on AWS 📚

Serverless lead capture platform built on AWS. Hosts a static site via S3 + CloudFront (CDN for global performance), routes traffic through Route 53 with HTTPS enforced via ACM, captures leads through API Gateway + Lambda, persists data in DynamoDB, and triggers email notifications via SES. IaC managed with Terraform.

---

## Architecture Diagram

![Architecture Diagram](/Images/Architecture_Diagram_Serverless_Lead_Capture.png)

---

## Architecture Overview

| Layer | Service |
|---|---|
| DNS & Domain | Route 53 |
| CDN & HTTPS | CloudFront + ACM |
| Static Hosting | S3 (bucket policies) |
| API Layer | API Gateway |
| Business Logic | AWS Lambda |
| Database | DynamoDB |
| Email Notifications | SES |
| Monitoring | CloudWatch |
| Infrastructure as Code | Terraform |

---

## Customer Requirements

- Static website built with HTML, CSS, and JavaScript
- Users can download an eBook directly from the site
- Contact details are captured and stored in DynamoDB for analytics
- Email notification triggered on every download via SES
- Global customer base — CloudFront CDN used for low-latency delivery
- ~500 active users, 10–15 downloads per day
- All requests served over HTTPS
- Custom domain: theepicbooks.com

---

## Project Walkthrough

1. **Hosting the static website** — S3 bucket configured for static site hosting with CloudFront distribution and ACM SSL certificate
2. **Serverless lead capture endpoint** — API Gateway triggers a Lambda function to process form submissions
3. **Persisting leads in DynamoDB** — Lambda writes contact details to a DynamoDB table on each download

---

## What I Learned

- Provisioning and connecting core AWS services end-to-end
- Writing reusable Terraform modules for serverless infrastructure
- Enforcing HTTPS and managing SSL certificates with ACM
- Designing event-driven workflows with Lambda and API Gateway
- Using CloudWatch for logging and monitoring Lambda functions

---
