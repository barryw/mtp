/* Create the combined instance. This instance runs MTP web and the database and is not autoscalable. */
resource "aws_instance" "combined" {
  depends_on             = [aws_ebs_encryption_by_default.application]
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.autoscaling["instance_type"] # We're not autoscaling, but let's just use the same instance type
  key_name               = var.key_name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.instances.id]
  iam_instance_profile   = aws_iam_instance_profile.instances.id
  user_data              = local.user_data_combined

  root_block_device {
    volume_type           = var.ebs["type"]
    volume_size           = var.ebs["size"]
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.product}-${var.environment}-primary"
    Product     = var.product
    Environment = var.environment
  }
}
