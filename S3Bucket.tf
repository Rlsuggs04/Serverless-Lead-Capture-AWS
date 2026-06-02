# Creating the S3 Bucket
resource "aws_s3_bucket" "epicreads-roberts-v3" {
  bucket = "epicreads-roberts-v3"
}

# Enable Static Website Hosting
resource "aws_s3_bucket_website_configuration" "epicreads-roberts-v3" {
  bucket = aws_s3_bucket.epicreads-roberts-v3.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload Ebook folder contents. The ${path.module} variable ensures we reference the correct path to the Ebook folder in our project. It automatically resolves to the directory where the main.tf lives.
resource "aws_s3_object" "ebook_files" {
  for_each = fileset("${path.module}/Ebook", "**/*") #Fileset + foreach iterates over everything inside the Ebook/ folder and uploads it to S3, preserving the directory structure.

  bucket = aws_s3_bucket.epicreads-roberts-v3.id
  key    = "Ebook/${each.value}"
  source = "${path.module}/Ebook/${each.value}"
  etag   = filemd5("${path.module}/Ebook/${each.value}") #Uses an MD5 hash so Terraform detects and re-uploads files that have changed.

  content_type = lookup({ #Sets the correct MIME type per file extension, ensuring browsers render them properly when accessed via the website endpoint.
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# Output the website URL in the terminal after applying the Terraform configuration. This allows us to easily access the static website hosted on S3 without needing to look up the endpoint manually.
output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.epicreads-roberts-v3.website_endpoint}/Ebook/index.html"
}