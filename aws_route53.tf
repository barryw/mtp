/* Internal Route53 Zone */
resource "aws_route53_zone" "internal" {
  vpc {
    vpc_id = module.vpc.vpc_id
  }

  name = "mtp.internal"
}

/* Create a record pointing at the bastion's public IP */
resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "bastion.${var.public_route53_zone}"
  type    = "A"
  ttl     = 60
  records = [aws_instance.bastion.public_ip]
}

/* Create a Route53 record to our combined instance, which holds the database */
resource "aws_route53_record" "combined" {
  zone_id = aws_route53_zone.internal.id
  name    = "db"
  type    = "A"
  ttl     = 60
  records = [aws_instance.combined.private_ip]
}

/* Application apex alias record */
resource "aws_route53_record" "application" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.public_route53_zone
  type    = "A"

  alias {
    name                   = aws_alb.application.dns_name
    zone_id                = aws_alb.application.zone_id
    evaluate_target_health = true
  }
}

/* Create a record for www */
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "www.${var.public_route53_zone}"
  type    = "A"

  alias {
    name                   = aws_alb.application.dns_name
    zone_id                = aws_alb.application.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "adminer" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = "adminer.${var.public_route53_zone}"
  type    = "A"

  alias {
    name                   = aws_alb.application.dns_name
    zone_id                = aws_alb.application.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_route53_record" "cert_validation_alt1" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = aws_acm_certificate.cert.domain_validation_options.1.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.1.resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options.1.resource_record_value]
  ttl     = 60
}

resource "aws_route53_record" "cert_validation_alt2" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = aws_acm_certificate.cert.domain_validation_options.2.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.2.resource_record_type
  records = [aws_acm_certificate.cert.domain_validation_options.2.resource_record_value]
  ttl     = 60
}
