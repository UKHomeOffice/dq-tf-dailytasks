# RDS Daily shutdown script
provider "aws" {
  region  =   "eu-west-2"
}


data "archive_file" "rds_shutdownzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/code/rds_shutdown.py"
  output_path = "${local.path_module}/lambda/package/rds_shutdown.zip"
}


resource "aws_lambda_function" "rds-shutdown-function" {
    function_name = "rds_shutdown-${var.naming_suffix}"
    handler ="rds_shutdown.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.rds-shutdown_role.arn}"
    filename = "${path.module}/lambda/package/rds_shutdown.zip"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.rds_shutdownzip.output_base64sha256}"

    tags = {
       Name  =  "rds_shutdown-${local.naming_suffix}"
    }
}

# IAM role

resource "aws_iam_role" "rds-shutdown_role" {
    name = "rds-shutdown_role-${var.namespace}"

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

# IAM Policy

data "aws_iam_policy_document" "eventwatch_logs_doc" {
    statement {
        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents"
        ]
        resources = [
            "arn:aws:logs:*:*:*",
        ]
    }
}

data "aws_iam_policy_document" "eventwatch_rds_doc" {
    statement {
        actions = [
            "rds:DescribeDBInstances",
            "rds:StartDBInstances",
            "rds:StopDBInstances"
        ]
        resources = [
            "*"
        ]
    }
}

resource "aws_iam_policy" "eventwatch_logs_policy" {
    name  =  "eventwatch_logs_policy-${var.namespace}"
    path  = "/"
    policy = "${data.aws_iam_policy_document.eventwatch_logs_doc.json}"
}

resource "aws_iam_policy" "eventwatch_rds_policy" {
    name = "eventwatch_rds_policy-${var.namespace}"
    path = "/"
    policy = "${data.aws_iam_policy_document.eventwatch_rds_doc.json}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_logs_policy_attachment" {
    role     =   "${aws_iam_role.rds-shutdown_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_logs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_rds_policy_attachment" {
    role    =    "${aws_iam_role.rds-shutdown_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_rds_policy.arn}"
}


# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_rds-shutdown" {
    name  =  "daily_rds-shutdown-${var.namespace}"
    description = "triggers daily RDS shutdown"
    schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

# Defines target for the rule - the Lambda function to trigger
# Points to the Lamda function

resource "aws_cloudwatch_event_target" "rds_lambda_target" {
    target_id = "rds-shutdown-function"
    rule      = "${aws_cloudwatch_event_rule.daily_rds-shutdown.name}"
    arn       = "${aws_lambda_function.rds-shutdown-function.arn}"
}
