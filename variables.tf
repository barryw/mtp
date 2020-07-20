variable "aws_region" {
  description = "The region to configure the AWS provider for"
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "The AWS profile to use from ~/.aws/credentials"
  default     = "default"
}

variable "product" {
  description = "The universal name of the product"
  default     = "mtp"
}

variable "environment" {
  description = "The environment that the product will be deployed to"
  default     = "production"
}

variable "vpc_cidr" {
  description = "The CIDR range to use for this product environment's VPC"
  default     = "10.2.0.0/16"
}

variable "key_name" {
  description = "The name of the AWS keypair to use for all instances provisioned. Must already exist!"
}

variable "public_route53_zone" {
  description = "The domain name of the public zone to configure the ALB for"
  default     = "containercurious.com"
}

variable "autoscaling" {
  description = "Default settings for the application's ASG"
  type        = map
  default = {
    min           = 2
    max           = 5
    desired       = 2
    instance_type = "t3.medium"
  }
}

variable "ses" {
  description = "Variables for configuring SES"
  type        = map
  default = {
    from = "barry@containercurious.com"
    name = "Barry Walker"
  }
}

variable "ebs" {
  description = "Variables for configuring server EBS volumes"
  type        = map
  default = {
    size      = 32
    encrypted = true
    type      = "gp2"
  }
}
