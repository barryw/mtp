/* Create our ACM cert */
/* NOTE: There's an issue where SAN may be returned in a different order each time causing Terraform to */
/* re-create the certificate. https://github.com/terraform-providers/terraform-provider-aws/issues/8531 */
resource "aws_acm_certificate" "cert" {
  domain_name               = var.public_route53_zone
  subject_alternative_names = ["www.${var.public_route53_zone}", "adminer.${var.public_route53_zone}"]
  validation_method         = "DNS"

  tags = {
    Name        = "${var.product}-${var.environment}-acm"
    Product     = var.product
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn, aws_route53_record.cert_validation_alt1.fqdn, aws_route53_record.cert_validation_alt2.fqdn]
}
