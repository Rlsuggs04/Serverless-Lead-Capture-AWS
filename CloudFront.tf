# Creates the CloudFront Origin Access Control which restricts direct access to the S3 bucket and ensures all traffic flows through CloudFront only
resource "aws_cloudfront_origin_access_control" "epicreads" {
  name                              = "epicreads-oac"
  description                       = "OAC for epicreads S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Creates the CloudFront distribution which sits in front of your S3 bucket serving your static site globally over HTTPS using your ACM certificate
resource "aws_cloudfront_distribution" "epicreads" {
  enabled             = true
  default_root_object = "Ebook/index.html"
  aliases             = ["epicreads.rsuggs.dev"]

  # Points CloudFront to your S3 bucket as the origin (where content lives)
  origin {
    domain_name              = aws_s3_bucket.epicreads-roberts-v3.bucket_regional_domain_name
    origin_id                = "epicreads-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.epicreads.id
  }

  # Defines how CloudFront handles and caches incoming requests
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "epicreads-s3-origin"
    viewer_protocol_policy = "redirect-to-https" #Any HTTP request will be redirected to HTTPS, ensuring secure connections to your site.

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Restricts the geographic locations from which users can access your content using no restrictions here so the site is accessible globally
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Attaches your ACM certificate to the distribution and enforces HTTPS. SNI is the standard and free method for SSL, dedicated IP costs extra
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.epicreads.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = {
    Name = "epicreads-distribution"
  }
}

# Updates the S3 bucket policy to only allow CloudFront to access the bucket directly via the OAC, blocking any direct public S3 access
resource "aws_s3_bucket_policy" "epicreads_cloudfront" {
  bucket = aws_s3_bucket.epicreads-roberts-v3.arn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.epicreads-roberts-v3.arn}/Ebook/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.epicreads.arn
          }
        }
      }
    ]
  })
}

# Creates the Route 53 A record that points epicreads.rsuggs.dev to the CloudFront distribution so traffic gets routed correctly
resource "aws_route53_record" "epicreads" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "epicreads.rsuggs.dev"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.epicreads.domain_name
    zone_id                = aws_cloudfront_distribution.epicreads.hosted_zone_id
    evaluate_target_health = false
  }
}

# Outputs the CloudFront distribution domain name and the live site URL
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.epicreads.domain_name
}

output "site_url" {
  value = "https://epicreads.rsuggs.dev"
}