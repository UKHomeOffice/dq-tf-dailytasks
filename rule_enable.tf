data "archive_file" "rule_enable_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/rule_enable.py"
  output_path = "${local.path_module}/lambda/package/rule_enable.zip"
}

resource "aws_lambda_function" "rule_enable" {
  count            = var.namespace == "prod" ? "0" : "1"
  filename         = "${path.module}/lambda/package/rule_enable.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-rule-enable"
  role             = aws_iam_role.rule_enable[0].arn
  handler          = "rule_enable.lambda_handler"
  source_code_hash = data.archive_file.rule_enable_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = "900"
  memory_size      = "128"
  environment {
    variables = {
      RULE_NAMES = "daily_ec2_shutdown,daily_ec2_startup,daily_rds_shutdown,daily_rds_startup"
    }
  }

  tags = {
    Name = "rule-enable-${local.naming_suffix}"
  }

  #   lifecycle {
  #     ignore_changes = [
  #       filename,
  #       last_modified,
  #       source_code_hash,
  #     ]
  #   }
}

resource "aws_iam_role" "rule_enable" {
  count = var.namespace == "prod" ? "0" : "1"
  name  = "${var.pipeline_name}-${var.namespace}-rule-enable"

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
    Name = "rule-enable-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "rule_enable" {
  count       = var.namespace == "prod" ? "0" : "1"
  name        = "${var.pipeline_name}-rule-enable"
  path        = "/"
  description = "IAM policy for disabling rules"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "events:EnableRule",
                "events:DescribeRule"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "rule_enable" {
  count      = var.namespace == "prod" ? "0" : "1"
  role       = aws_iam_role.rule_enable[0].name
  policy_arn = aws_iam_policy.rule_enable[0].arn
}

resource "aws_cloudwatch_event_target" "rule_enable" {
  count = var.namespace == "prod" ? "0" : "1"
  rule  = aws_cloudwatch_event_rule.rule_enable[0].name
  arn   = aws_lambda_function.rule_enable[0].arn


}

resource "aws_cloudwatch_event_rule" "rule_enable" {
  count               = var.namespace == "prod" ? "0" : "1"
  name                = "holiday_eventrule_enable"
  description         = "enable daily startup and shutdown for ec2 and RDS"
  schedule_expression = "cron(0 18 1 1 ? 2025)"
  is_enabled          = "true"
}