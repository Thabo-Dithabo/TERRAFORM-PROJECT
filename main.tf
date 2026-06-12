provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

############################################
# Route 53 Hosted Zone
############################################

resource "aws_route53_zone" "main" {
  name = "tharonglabs.com"
}

############################################
# S3 Bucket
############################################

resource "aws_s3_bucket" "firstbucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "firstbucket" {
  bucket = aws_s3_bucket.firstbucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



############################################
# CloudFront Origin Access Control (OAC)
############################################

resource "aws_cloudfront_origin_access_control" "osc_firstbucket" {
  name                              = "demo-osc"
  description                       = "S3 OAC for CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.firstbucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = "s3:GetObject"

        Resource = "${aws_s3_bucket.firstbucket.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn"   = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}
############################################
# ACM Certificate
############################################

resource "aws_acm_certificate" "tharonglabs" {
  provider          = aws.us-east-1
  domain_name       = "tharonglabs.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.tharonglabs.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

############################################
# ACM DNS Validation Records
############################################

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.tharonglabs.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

############################################
# ACM Certificate Validation
############################################

resource "aws_acm_certificate_validation" "tharonglabs" {
  certificate_arn         = aws_acm_certificate.tharonglabs.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}

############################################
# Upload website files to S3
############################################

locals {
  mime_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = fileset("${path.module}/www", "**/*")

  bucket = aws_s3_bucket.firstbucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag   = filemd5("${path.module}/www/${each.value}")

  content_type = lookup(
    local.mime_types,
    split(".", each.value)[length(split(".", each.value)) - 1],
    "application/octet-stream"
  )
}

############################################
# CloudFront Distribution
############################################

resource "aws_cloudfront_distribution" "s3_distribution" {

  aliases = [
    "tharonglabs.com",
    "www.tharonglabs.com"
  ]

  origin {
    domain_name = aws_s3_bucket.firstbucket.bucket_regional_domain_name
    origin_id   = "s3-firstbucket"

    origin_access_control_id = aws_cloudfront_origin_access_control.osc_firstbucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "S3 + CloudFront website"
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "s3-firstbucket"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"

     forwarded_values {
    query_string = false

    cookies {
      forward = "none"
    }
  }

    min_ttl     = 0
    default_ttl  = 3600
    max_ttl      = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.tharonglabs.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

############################################
# Route 53 → CloudFront (Root Domain)
############################################

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "tharonglabs.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

############################################
# Route 53 → CloudFront (WWW)
############################################

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.tharonglabs.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
