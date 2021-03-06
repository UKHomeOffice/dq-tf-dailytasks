data "archive_file" "rds_shutdown_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/rds_shutdown.py"
  output_path = "${local.path_module}/lambda/package/rds_shutdown.zip"
}

resource "aws_lambda_function" "rds_shutdown" {
  count            = var.namespace == "prod" ? "0" : "1"
  filename         = "${path.module}/lambda/package/rds_shutdown.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-rds-shutdown"
  role             = aws_iam_role.rds_shutdown[0].arn
  handler          = "rds_shutdown.lambda_handler"
  source_code_hash = data.archive_file.rds_shutdown_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }

  # lifecycle {
  #   ignore_changes = [
  #     filename,
  #     last_modified,
  #     source_code_hash,
  #   ]
  # }
}

resource "aws_iam_role" "rds_shutdown" {
  count = var.namespace == "prod" ? "0" : "1"
  name  = "${var.pipeline_name}-${var.namespace}-rds-shutdown"

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
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "rds_shutdown" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-rds-shutdown"
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
              "rds:Describe*",
              "rds:Stop*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rds_shutdown" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.rds_shutdown[0].name
  policy_arn = aws_iam_policy.rds_shutdown[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_rds_shutdown" {
  count             = var.namespace == "prod" ? "0" : "1"
  name              = "/aws/lambda/${aws_lambda_function.rds_shutdown[0].function_name}"
  retention_in_days = 14

  tags = {
    Name = "rds-shutdown-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_rds_shutdown_logging" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-rds-shutdown-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:GetMetricStatistics",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.lambda_rds_shutdown[0].arn}",
        "${aws_cloudwatch_log_group.lambda_rds_shutdown[0].arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_rds_shutdown_logs" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.rds_shutdown[0].name
  policy_arn = aws_iam_policy.lambda_rds_shutdown_logging[0].arn
}
