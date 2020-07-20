resource "aws_autoscaling_group" "application" {
  name                      = "${var.product}-${var.environment}-application"
  launch_configuration      = aws_launch_configuration.application.name
  min_size                  = var.autoscaling["min"]
  max_size                  = var.autoscaling["max"]
  desired_capacity          = var.autoscaling["desired"]
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "ELB"
  health_check_grace_period = 600

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.product}-${var.environment}-application"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Product"
    value               = var.product
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "application" {
  depends_on                  = [aws_ebs_encryption_by_default.application]
  name_prefix                 = "${var.product}-${var.environment}-application-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.autoscaling["instance_type"]
  key_name                    = var.key_name
  security_groups             = [aws_security_group.instances.id]
  associate_public_ip_address = false
  user_data                   = local.user_data_autoscale
  iam_instance_profile        = aws_iam_instance_profile.instances.id

  root_block_device {
    volume_type           = var.ebs["type"]
    volume_size           = var.ebs["size"]
    delete_on_termination = true
    encrypted             = var.ebs["encrypted"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

/* Attach our autoscaling group to our target group */
resource "aws_autoscaling_attachment" "application" {
  autoscaling_group_name = aws_autoscaling_group.application.id
  alb_target_group_arn   = aws_alb_target_group.application.arn
}

resource "aws_autoscaling_policy" "app-scale-up" {
  name                   = "${var.product}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.application.name
}

resource "aws_cloudwatch_metric_alarm" "high-cpu" {
  alarm_name          = "${var.product}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Monitor for high CPU usage so that we can scale up."
  alarm_actions = [
    aws_autoscaling_policy.app-scale-up.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }
}

resource "aws_autoscaling_policy" "app-scale-down" {
  name                   = "${var.product}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.application.name
}

resource "aws_cloudwatch_metric_alarm" "low-cpu" {
  alarm_name          = "${var.product}-${var.environment}-low-cpu"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Monitor for low CPU usage so that we can scale down."
  alarm_actions = [
    aws_autoscaling_policy.app-scale-down.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.application.name
  }
}
