resource "aws_instance" "bastion" {
  depends_on             = [aws_ebs_encryption_by_default.application]
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.nano"
  key_name               = var.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.product}-${var.environment}-bastion"
    Product     = var.product
    Environment = var.environment
  }
}
