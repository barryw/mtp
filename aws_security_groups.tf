resource "aws_security_group" "bastion" {
  name        = "${var.product}-${var.environment}-bastion"
  description = "SSH from anywhere"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.product}-${var.environment}-bastion"
    Product     = var.product
    Environment = var.environment
  }
}

/* Security Group for our instances */
resource "aws_security_group" "instances" {
  name        = "${var.product}-${var.environment}-instances"
  description = "SSH, MySQL from within VPC, HTTP from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.application-alb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.application-alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.product}-${var.environment}-instances"
    Product     = var.product
    Environment = var.environment
  }
}

/* Security Group for ALB */
resource "aws_security_group" "application-alb" {
  name        = "${var.product}-${var.environment}-alb"
  description = "HTTPS from the world"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.product}-${var.environment}-alb"
    Product     = var.product
    Environment = var.environment
  }
}
