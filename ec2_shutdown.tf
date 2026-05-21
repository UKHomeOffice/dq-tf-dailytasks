data "archive_file" "ec2_shutdown_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/ec2_shutdown.py"
  output_path = "${local.path_module}/lambda/package/ec2_shutdown.zip"
}


data "archive_file" "ec2_shutdown_prod_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/ec2_shutdown_prod.py"
  output_path = "${local.path_module}/lambda/package/ec2_shutdown_prod.zip"
}

resource "aws_lambda_function" "ec2_shutdown" {
  count            = var.namespace == "prod" ? "0" : "1"
  filename         = "${path.module}/lambda/package/ec2_shutdown.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-ec2-shutdown"
  role             = aws_iam_role.ec2_shutdown[0].arn
  handler          = "ec2_shutdown.lambda_handler"
  source_code_hash = data.archive_file.ec2_shutdown_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "ec2-shutdown-${local.naming_suffix}"
  }

  #   lifecycle {
  #     ignore_changes = [
  #       filename,
  #       last_modified,
  #       source_code_hash,
  #     ]
  #   }
}

resource "aws_lambda_function" "ec2_shutdown_prod" {
  count            = var.namespace == "prod" ? "0" : "0"
  filename         = "${path.module}/lambda/package/ec2_shutdown_prod.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-ec2-shutdown"
  role             = aws_iam_role.ec2_shutdown[0].arn
  handler          = "ec2_shutdown.lambda_handler"
  source_code_hash = data.archive_file.ec2_shutdown_zip[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 900
  memory_size      = 128

  environment {
    variables = {
      ACTIVE_REGION               = var.region
      SHUTDOWN_EXCLUDED_NAME_TAGS = join(",", var.ec2_prod_scheduled_instance_names)
    }
  }

  tags = {
    Name = "ec2-shutdown-${local.naming_suffix}"
  }

  #   lifecycle {
  #     ignore_changes = [
  #       filename,
  #       last_modified,
  #       source_code_hash,
  #     ]
  #   }

}


resource "aws_iam_role" "ec2_shutdown" {
  count = var.namespace == "prod" ? "0" : "1"
  name  = "${var.pipeline_name}-${var.namespace}-ec2-shutdown"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF


  tags = {
    Name = "ec2-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "ec2_shutdown" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-ec2-shutdown"
  path        = "/"
  description = "IAM policy for describing snapshots"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StopInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ec2_shutdown" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.ec2_shutdown[0].name
  policy_arn = aws_iam_policy.ec2_shutdown[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_ec2_shutdown" {
  count             = var.namespace == "prod" ? "0" : "1"
  name              = "/aws/lambda/${aws_lambda_function.ec2_shutdown[0].function_name}"
  retention_in_days = 14

  tags = {
    Name = "ec2-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_ec2_shutdown_logging" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-ec2-shutdown-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.lambda_ec2_shutdown[0].arn}",
        "${aws_cloudwatch_log_group.lambda_ec2_shutdown[0].arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_ec2_shutdown_logs" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.ec2_shutdown[0].name
  policy_arn = aws_iam_policy.lambda_ec2_shutdown_logging[0].arn
}
