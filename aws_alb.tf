resource "aws_alb" "application" {
  name               = "${var.product}-${var.environment}-application"
  internal           = false
  security_groups    = [aws_security_group.application-alb.id]
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"

  tags = {
    Name        = "${var.product}-${var.environment}-application"
    Product     = var.product
    Environment = var.environment
  }
}

/* Handle HTTPS requests */
resource "aws_alb_listener" "application" {
  load_balancer_arn = aws_alb.application.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    target_group_arn = aws_alb_target_group.application.arn
    type             = "forward"
  }
}

/* Redirect HTTP -> HTTPS */
resource "aws_alb_listener" "application-http" {
  load_balancer_arn = aws_alb.application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

/* Set up a listener rule to direct adminer traffic to the correct container */
resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_alb_listener.application.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.adminer.arn
  }

  condition {
    host_header {
      values = ["adminer.${var.public_route53_zone}"]
    }
  }
}

resource "aws_alb_target_group" "application" {
  name     = "${var.product}-${var.environment}-application"
  protocol = "HTTP"
  port     = 80
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    protocol            = "HTTP"
    path                = "/Healthcheck"
    matcher             = "200"
  }
}

resource "aws_alb_target_group" "adminer" {
  name     = "${var.product}-${var.environment}-adminer"
  protocol = "HTTP"
  port     = 8080
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "combined-application" {
  target_group_arn = aws_alb_target_group.application.arn
  target_id        = aws_instance.combined.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "combined-adminer" {
  target_group_arn = aws_alb_target_group.adminer.arn
  target_id        = aws_instance.combined.id
  port             = 8080
}
