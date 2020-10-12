data "archive_file" "monitor_stage_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/monitor_stage.py"
  output_path = "${local.path_module}/lambda/package/monitor_stage.zip"
}

resource "aws_lambda_function" "monitor_stage" {
  count            = var.namespace == "prod" ? "1" : "0"
  filename         = "${path.module}/lambda/package/monitor_stage.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-monitor-stage"
  role             = aws_iam_role.monitor_stage[0].arn
  handler          = "monitor_stage.lambda_handler"
  source_code_hash = data.archive_file.monitor_stage_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "monitor-stage-${local.naming_suffix}"
  }

  #   lifecycle {
  #     ignore_changes = [
  #       filename,
  #       last_modified,
  #       source_code_hash,
  #     ]
  #   }
}

resource "aws_iam_role" "monitor_stage" {
  count = var.namespace == "prod" ? "1" : "0"
  name  = "${var.pipeline_name}-${var.namespace}-monitor-stage"

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
    Name = "monitor-stage-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "monitor_stage" {
  count       = var.namespace == "prod" ? "1" : "0"
  name        = "${var.pipeline_name}-monitor-stage"
  path        = "/"
  description = "IAM policy Monitor-stage function"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "rds:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "monitor_stage" {
  count      = var.namespace == "prod" ? "1" : "0"
  role       = aws_iam_role.monitor_stage[0].name
  policy_arn = aws_iam_policy.monitor_stage[0].arn
}

resource "aws_cloudwatch_log_group" "lambda_monitor_stage" {
  count             = var.namespace == "prod" ? "1" : "0"
  name              = "/aws/lambda/${aws_lambda_function.monitor_stage[0].function_name}"
  retention_in_days = 14

  tags = {
    Name = "monitor-stage-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_monitor_stage_logging" {
  count       = var.namespace == "prod" ? "1" : "0"
  name        = "${var.pipeline_name}-monitor-stage-logging"
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
        "${aws_cloudwatch_log_group.lambda_monitor_stage[0].arn}",
        "${aws_cloudwatch_log_group.lambda_monitor_stage[0].arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_monitor_stage_logs" {
  count      = var.namespace == "prod" ? "1" : "0"
  role       = aws_iam_role.monitor_stage[0].name
  policy_arn = aws_iam_policy.lambda_monitor_stage_logging[0].arn
}
