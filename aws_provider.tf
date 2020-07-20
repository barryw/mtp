provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {}
}

/* Enable EBS encryption by default */
resource "aws_ebs_encryption_by_default" "application" {
  enabled = true
}
