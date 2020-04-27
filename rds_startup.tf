data "archive_file" "rds_startup_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/rds_startup.py"
  output_path = "${local.path_module}/lambda/package/rds_startup.zip"
}

resource "aws_lambda_function" "rds_startup" {
  filename         = "${path.module}/lambda/package/rds_startup.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-rds-startup"
  role             = "${aws_iam_role.rds_startup.arn}"
  handler          = "rds_startup.lambda_handler"
  source_code_hash = "${data.archive_file.rds_startup_zip.output_base64sha256}"
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "rds-startup-${local.naming_suffix}"
  }
}

resource "aws_iam_role" "rds_startup" {
  name = "${var.pipeline_name}-${var.namespace}-rds-startup"

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
    Name = "rds-startup-${local.naming_suffix}"
  }

}

resource "aws_iam_policy" "rds_startup" {
  name        = "${var.pipeline_name}-rds-startup"
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
                "rds:DescribeDBInstance",
                "rds:StartDBInstance"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rds_startup" {
  role       = "${aws_iam_role.rds_startup.name}"
  policy_arn = "${aws_iam_policy.rds_startup.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_rds_startup" {
  name              = "/aws/lambda/${aws_lambda_function.rds_startup.function_name}"
  retention_in_days = 14

  tags = {
    Name = "rds-startup-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_rds_startup_logging" {
  name        = "${var.pipeline_name}-rds-startup-logging"
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
        "${aws_cloudwatch_log_group.lambda_rds_startup.arn}",
        "${aws_cloudwatch_log_group.lambda_rds_startup.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_rds_startup_logs" {
  role       = "${aws_iam_role.rds_startup.name}"
  policy_arn = "${aws_iam_policy.lambda_rds_startup_logging.arn}"
}
