/* Generate UserData for both the combined instance and the autoscaled instances */
locals {
  user_data_combined = templatefile("${path.module}/scripts/userdata.sh",
    {
      instance_type  = "combined",
      ses_from_email = var.ses["from"],
      ses_from_name  = var.ses["name"],
      region         = var.aws_region
    }
  )

  user_data_autoscale = templatefile("${path.module}/scripts/userdata.sh",
    {
      instance_type  = "autoscale",
      ses_from_email = var.ses["from"],
      ses_from_name  = var.ses["name"],
      region         = var.aws_region
    }
  )
}
