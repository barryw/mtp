/* Grant our instances permissions talk to SNS and SES */
resource "aws_iam_role" "instances" {
  name = "${var.product}-${var.environment}-instances"

  assume_role_policy = <<EOF
{ "Version": "2012-10-17",
  "Statement": [
    { "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instances" {
  name = "${var.product}-${var.environment}-instances"
  role = aws_iam_role.instances.id
}

resource "aws_iam_role_policy" "instances" {
  name = "${var.product}-${var.environment}-instances"
  role = aws_iam_role.instances.id

  policy = <<EOF
{ "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SESAccess",
      "Effect": "Allow",
      "Action": [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "SNSAccess",
      "Effect": "Allow",
      "Action": [
        "sns:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
