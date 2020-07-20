/* Get our AZs for the specified region */
data "aws_availability_zones" "available" {
  state = "available"
}

/* Our external Route53 zone */
data "aws_route53_zone" "domain" {
  name = "${var.public_route53_zone}."
}

/* Use Ubuntu 18.04 LTS */
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

/* Use ifconfig.me to get our IP. This will be the only IP allowed to connect to the bastion */
data "http" "myip" {
  url = "http://ifconfig.me"
}
