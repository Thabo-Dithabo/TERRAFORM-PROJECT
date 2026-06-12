# TERRAFORM-PROJECT
# AWS Static Website Hosting with Terraform

## Project Overview



The infrastructure provisions:

* Amazon S3 for website storage
* Amazon CloudFront for global content delivery
* AWS Certificate Manager (ACM) for SSL/TLS certificates
* Amazon Route 53 for DNS management
* CloudFront Origin Access Control (OAC) for secure S3 access
* Terraform for Infrastructure as Code (IaC)

---

# Architecture Diagram

```text
                    Internet Users
                           |
                           |
                    +-------------+
                    |  Route 53   |
                    |    DNS      |
                    +-------------+
                           |
                           |
                    +-------------+
                    | CloudFront  |
                    | Distribution|
                    +-------------+
                           |
                 Origin Access Control
                           |
                           |
                    +-------------+
                    | Private S3  |
                    |   Bucket    |
                    +-------------+
                           |
                           |
                    Website Files
                index.html, images
```

---

# Architecture Flow

1. User accesses the website.
2. Route 53 resolves the domain name.
3. CloudFront receives the request.
4. CloudFront retrieves content from the S3 bucket.
5. Origin Access Control securely authorizes CloudFront.
6. Website content is delivered over HTTPS.

---

# Technologies Used

| Technology | Purpose                    |
| ---------- | -------------------------- |
| Terraform  | Infrastructure as Code     |
| Amazon S3  | Static website storage     |
| CloudFront | Content Delivery Network   |
| ACM        | SSL Certificate Management |
| Route53    | DNS Management             |
| OAC        | Secure S3 Access           |

---

# Project Structure

```text
project/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
│
├── www/
│   ├── index.html
│   └── mountains.jpg
│
├── screenshots/
│   ├── architecture-diagram.png
│   ├── terraform-apply-success.png
│   ├── s3-bucket-objects.png
│   ├── cloudfront-distribution.png
│   ├── acm-certificate-issued.png
│   ├── route53-records.png
│   └── website-live.png
│
└── README.md
```

---

# Infrastructure Components

## S3 Bucket

Stores website files securely.

Features:

* Private bucket
* Public access blocked
* Content uploaded automatically using Terraform

---

## CloudFront Distribution

Provides:

* Global content delivery
* HTTPS support
* Edge caching
* Custom domain support

Configuration:

* Default Root Object: index.html
* Viewer Protocol Policy: Redirect HTTP to HTTPS
* Origin Access Control enabled

---

## ACM Certificate

SSL certificate created in:

```text
us-east-1
```

Required for CloudFront HTTPS support.

Domains:

```text
tharonglabs.com
www.tharonglabs.com
```

---

## Route53

Creates:

* Hosted Zone
* Root Domain Record
* WWW Record
* ACM Validation Records

---

# Deployment Steps

## Initialize Terraform

```bash
terraform init
```

---

## Validate Configuration

```bash
terraform validate
```

---

## Format Code

```bash
terraform fmt
```

---

## Review Deployment Plan

```bash
terraform plan
```

---

## Deploy Infrastructure

```bash
terraform apply
```

---

# Challenges Encountered

## Issue 1: AccessDenied Error

### Error

```xml
<Error>
    <Code>AccessDenied</Code>
    <Message>Access Denied</Message>
</Error>
```

### Root Cause

CloudFront was configured with Origin Access Control (OAC), but the S3 bucket policy was missing.

CloudFront could not access objects inside the private bucket.

### Solution

Created an S3 bucket policy allowing CloudFront access.

```hcl
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.firstbucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "cloudfront.amazonaws.com"
      }

      Action = "s3:GetObject"

      Resource = "${aws_s3_bucket.firstbucket.arn}/*"

      Condition = {
        StringEquals = {
          AWS:SourceArn = aws_cloudfront_distribution.s3_distribution.arn
        }
      }
    }]
  })
}
```

### Lesson Learned

Origin Access Control secures S3 access but does not automatically grant permissions.

An S3 bucket policy is required.

---

## Issue 2: Certificate Validation Delays

### Root Cause

DNS validation records had not propagated yet.

### Solution

Terraform automatically created Route53 validation records.

Waited for ACM validation to complete.

---

## Issue 3: Website Not Resolving

### Root Cause

Domain registrar nameservers were not pointing to Route53.

### Solution

Updated nameservers at the registrar.

---

## Issue 4: Website Changes Not Appearing

### Root Cause

CloudFront caching.

### Solution

Created an invalidation:

```bash
aws cloudfront create-invalidation \
--distribution-id DISTRIBUTION_ID \
--paths "/*"
```

---

# Screenshots

## Terraform Apply Successful

![Terraform Apply](screenshots/terraform-apply-success.png)
<img width="1634" height="682" alt="image" src="https://github.com/user-attachments/assets/a65d385e-b3b3-4c84-90f6-d3dbd32a594a" />


---

## S3 Bucket Objects

![S3 Bucket](screenshots/s3-bucket-objects.png)
<img width="1771" height="729" alt="image" src="https://github.com/user-attachments/assets/7a0ee3d5-1c36-47f4-90db-323781428bb8" />


---

## ACM Certificate Issued

![ACM Certificate](screenshots/acm-certificate-issued.png)
<img width="1873" height="821" alt="image" src="https://github.com/user-attachments/assets/bd77b416-5f85-436e-ab37-d252ed5035de" />


---

## CloudFront Distribution

![CloudFront Distribution](screenshots/cloudfront-distribution.png)
<img width="1720" height="830" alt="image" src="https://github.com/user-attachments/assets/15bea87b-040c-40d5-9ff0-1934f5d63e42" />


---

## Route53 Records

![Route53 Records](screenshots/route53-records.png)
<img width="1702" height="760" alt="image" src="https://github.com/user-attachments/assets/58a9fb12-a5a7-44a7-8dda-7825137d29f6" />

---

## Successful Website Deployment

![Live Website](screenshots/website-live.png)
<img width="1919" height="945" alt="image" src="https://github.com/user-attachments/assets/75fd2638-3a75-420c-a83a-c48ee936a617" />

---

# Security Features

* Private S3 Bucket
* Block Public Access Enabled
* HTTPS Enforcement
* TLS 1.2+
* CloudFront Origin Access Control
* SSL Certificate via ACM

---

# Skills Demonstrated

* AWS Cloud Infrastructure
* Terraform
* Infrastructure as Code (IaC)
* CloudFront CDN
* Route53 DNS Management
* SSL/TLS Configuration
* Cloud Security
* Troubleshooting and Debugging
* Static Website Hosting
* AWS Networking

---

# Future Improvements

* CI/CD with GitHub Actions
* Terraform Remote State (S3 + DynamoDB)
* Multi-Environment Deployment
* Monitoring with CloudWatch
* AWS WAF Integration
* Automated Cache Invalidation

---

# Author

**Thabang**

Cloud & DevOps Enthusiast

AWS Certified Cloud Practitioner

Building hands-on cloud projects using AWS and Terraform.
