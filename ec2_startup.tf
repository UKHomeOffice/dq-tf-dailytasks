data "archive_file" "ec2_startup_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/ec2_startup.py"
  output_path = "${local.path_module}/lambda/package/ec2_startup.zip"
}

resource "aws_lambda_function" "ec2_startup" {
  filename         = "${path.module}/lambda/package/ec2_startup.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-ec2-startup"
  role             = "${aws_iam_role.ec2_startup.arn}"
  handler          = "ec2_startup.lambda_handler"
  source_code_hash = "${data.archive_file.ec2_startup_zip.output_base64sha256}"
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "ec2-startup-${local.naming_suffix}"
  }
}

resource "aws_iam_role" "ec2_startup" {
  name = "${var.pipeline_name}-${var.namespace}-ec2-startup"

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
    Name = "ec2-startup-${local.naming_suffix}"
  }

}

resource "aws_iam_policy" "ec2_startup" {
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
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_startup" {
  role       = "${aws_iam_role.ec2_startup.name}"
  policy_arn = "${aws_iam_policy.ec2_startup.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_ec2_startup" {
  name              = "/aws/lambda/${aws_lambda_function.ec2_startup.function_name}"
  retention_in_days = 14

  tags = {
    Name = "ec2-startup-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_ec2_startup_logging" {
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
        "${aws_cloudwatch_log_group.lambda_ec2_startup.arn}",
        "${aws_cloudwatch_log_group.lambda_ec2_startup.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_startup_logs" {
  role       = "${aws_iam_role.ec2_startup.name}"
  policy_arn = "${aws_iam_policy.lambda_ec2_startup_logging.arn}"
}
