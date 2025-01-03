data "archive_file" "ec2_startup_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/ec2_startup.py"
  output_path = "${local.path_module}/lambda/package/ec2_startup.zip"
}


resource "aws_kms_key" "dt_bucket_key" {
  count                   = var.namespace == "prod" ? "0" : "1"
  description             = "This key is used to encrypt daily tasks buckets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "daily-tasks-1",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
                  "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/dq-tf-infra"
                ]
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_lambda_function" "ec2_startup" {
  count            = var.namespace == "prod" ? "0" : "1"
  filename         = "${path.module}/lambda/package/ec2_startup.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-ec2-startup"
  role             = aws_iam_role.ec2_startup[0].arn
  handler          = "ec2_startup.lambda_handler"
  source_code_hash = data.archive_file.ec2_startup_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "ec2-startup-${local.naming_suffix}"
  }

  #   lifecycle {
  #     ignore_changes = [
  #       filename,
  #       last_modified,
  #       source_code_hash,
  #     ]
  #   }
}



resource "aws_iam_role" "ec2_startup" {
  count = var.namespace == "prod" ? "0" : "1"
  name  = "${var.pipeline_name}-${var.namespace}-ec2-startup"

  tags = {
    Name = "ec2-startup-${local.naming_suffix}"
  }

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
}

resource "aws_iam_policy" "ec2_startup" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-ec2-startup"
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
                "ec2:StartInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowS3GetObject",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::s3-dq-httpd-config-bucket-notprod/ssl.conf"
        },
        {
            "Sid": "",
            "Effect": "Allow", 
            "Action": [
                "kms:*"                
            ],
            "Resource": "*"
        }
    ]
}
EOF  

  depends_on = [aws_kms_key.dt_bucket_key]
}

resource "aws_iam_role_policy_attachment" "ec2_startup" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.ec2_startup[0].name
  policy_arn = aws_iam_policy.ec2_startup[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_ec2_startup" {
  count             = var.namespace == "prod" ? "0" : "1"
  name              = "/aws/lambda/${aws_lambda_function.ec2_startup[0].function_name}"
  retention_in_days = 14

  tags = {
    Name = "ec2-startup-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_ec2_startup_logging" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-ec2-startup-logging"
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
        "${aws_cloudwatch_log_group.lambda_ec2_startup[0].arn}",
        "${aws_cloudwatch_log_group.lambda_ec2_startup[0].arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_ec2_startup_logs" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.ec2_startup[0].name
  policy_arn = aws_iam_policy.lambda_ec2_startup_logging[0].arn
}
