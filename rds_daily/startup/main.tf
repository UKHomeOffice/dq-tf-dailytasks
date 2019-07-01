provider "aws" {
  region  =   "eu-west-2"
}


data "archive_file" "rds_startupzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/code/rds_startup.py"
  output_path = "${local.path_module}/lambda/package/rds_startupzip"
}


resource "aws_lambda_function" "rds_startup-function" {
    function_name = "rds_daily_startup"
    handler ="rds_startup.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.rds_startup_role.arn}"
    filename = "${path.module}/lambda/package/rds_startupzip"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.rds_startupzip.output_base64sha256}"
}

# IAM role

resource "aws_iam_role" "rds_startup_role" {
    name = "rds_startup_role"

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
    name  =  "eventwatch_logs_policy"
    path  = "/"
    policy = "${data.aws_iam_policy_document.eventwatch_logs_doc.json}"
}

resource "aws_iam_policy" "eventwatch_rds_policy" {
    name = "eventwatch_rds_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.eventwatch_rds_doc.json}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_logs_policy_attachment" {
    role     =   "${aws_iam_role.rds_startup_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_logs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_rds_policy_attachment" {
    role    =    "${aws_iam_role.rds_startup_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_rds_policy.arn}"
}


# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_rds_startup" {
    name  =  "daily_rds_startup"
    description = "triggers daily rds startup"
    schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

# Defines target for the rule - the Lambda function to trigger
# Points to the Lambda function

resource "aws_cloudwatch_event_target" "rds_lambda_target" {
    target_id = "rds_startup-function"
    rule      = "${aws_cloudwatch_event_rule.daily_rds_startup.name}"
    arn       = "${aws_lambda_function.rds_startup-function.arn}"
}
