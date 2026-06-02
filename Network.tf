variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for rsuggs.dev"
  type        = string
}

#Importing the existing hosted zone so Terraform doesn't try to create a duplicate.
import {
  to = aws_route53_zone.primary
  id = var.hosted_zone_id
}

#Defines the Route53 hosted zone for our domain, which is necessary for managing DNS records and validating our ACM certificate for the custom domain we'll use with CloudFront.
#Acts as the container for all DNS records related to our domain.
resource "aws_route53_zone" "primary" {
  name = "rsuggs.dev"
}

#Requests a public SSL/TLS certificate from AWS ACM. It will cover both epicreads.rsuggs.dev and www.epicreads.rsuggs.dev, allowing us to use HTTPS for our CloudFront distribution. 
#The certificate will be validated via DNS to prove domain ownership and RSA 2048 for encryption.
resource "aws_acm_certificate" "epicreads" {
  domain_name               = "epicreads.rsuggs.dev"
  subject_alternative_names = ["www.epicreads.rsuggs.dev"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true #Ensures a new cert is provisioned before the old one is destroyed during updates, preventing downtime for the CloudFront distribution that depends on this certificate.
  }

  tags = {
    Name = "epicreads-cert"
  }
}

#Creates the DNS validation records in Route53 that ACM requires to verify ownership of the domain. 
#It uses a for_each loop to iterate over each domain/subdomain in the certificate and creates the necessary CNAME records based on the validation options provided by ACM.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.epicreads.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

#Tells terraform to wait until the ACM has fully validated and issued the certificate before allowing dependent resources (like CloudFront) to be created. 
#Prevents apply from moving on before the cert is actually ready to use.
resource "aws_acm_certificate_validation" "epicreads" {
  certificate_arn         = aws_acm_certificate.epicreads.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}