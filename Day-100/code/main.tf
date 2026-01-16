resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "site_files" {
  for_each = fileset("${path.module}/../www", "**/*")

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${path.module}/../www/${each.value}"
  etag   = filemd5("${path.module}/../www/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "binary/octet-stream")
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "space9-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_acm_certificate" "cert" {
  provider = aws.us_east_1
  domain   = var.domain_name
  statuses = ["ISSUED"]
  most_recent = true
}
