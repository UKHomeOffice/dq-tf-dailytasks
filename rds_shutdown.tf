# RDS Daily shutdown script
provider "aws" {}

### Archive file - rds_shutdown lambda
data "archive_file" "rds_shutdownzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/code/rds_shutdown.py"
  output_path = "${local.path_module}/lambda/package/rds_shutdown.zip"
}

### Archive file - rds_startup lambda
data "archive_file" "rds_startupzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/startup/code/rds_startup.py"
  output_path = "${local.path_module}/lambda/startup/package/rds_startup.zip"
}

### Archive file - ec2_startup
data "archive_file" "ecstartzip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/startup/code/ec2-startup.py"
  output_path = "${local.path_module}/lambda/startup/package/ec2-startup.zip"
}

### Archive file - ec2_shutdown
data "archive_file" "ecshutzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/code/ec2-shutdown.py"
  output_path = "${local.path_module}/lambda/package/ec2-shutdown.zip"
}


resource "aws_lambda_function" "rds-shutdown-function" {
    function_name = "rds_shutdown-${var.naming_suffix}"
    handler ="rds_shutdown.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.rds-shutdown_role.arn}"
    filename = "${data.archive_file.rds_shutdownzip.output_path}"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.rds_shutdownzip.output_base64sha256}"

    tags = {
       Name  =  "rds_shutdown-${local.naming_suffix}"
    }
}

resource "aws_lambda_function" "rds_startup-function" {
    function_name = "rds_daily_startup-${var.naming_suffix}"
    handler ="rds_startup.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.rds_startup_role.arn}"
    filename = "${data.archive_file.rds_startupzip.output_path}"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.rds_startupzip.output_base64sha256}"

    tags = {
       Name  =  "rds_daily_startup-${local.naming_suffix}"
    }
}

resource "aws_lambda_function" "ec2-startup-function" {
  function_name    = "ec2_daily_startup-${var.naming_suffix}"
  handler          = "ec2-startup.lambda_handler"
  runtime          = "python3.7"
  role             = "${aws_iam_role.ec2_startup_role.arn}"
  filename         = "${data.archive_file.ecstartzip.output_path}"
  memory_size      = 128
  timeout          = 10
  source_code_hash = "${data.archive_file.ecstartzip.output_base64sha256}"

  tags = {
     Name   =   "ec2_daily_startup-${local.naming_suffix}"
  }
}

resource "aws_lambda_function" "ec2-shutdown-function" {
    function_name = "ec2_daily_shutdown-${var.naming_suffix}"
    handler ="ec2-shutdown.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.ec2_shutdown_role.arn}"
    filename = "${data.archive_file.ecshutzip.output_path}"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.ecshutzip.output_base64sha256}"

    tags = {
       Name  =  "ec2_daily_shutdown-${local.naming_suffix}"
    }
}

# IAM role

resource "aws_iam_role" "rds-shutdown_role" {
    name = "rds-shutdown_role-${var.naming_suffix}"

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
    Name = "rds-shutdown_role-${local.naming_suffix}"
  }
}

# IAM role

resource "aws_iam_role" "rds_startup_role" {
    name = "rds_startup_role-${var.naming_suffix}"

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
    Name = "rds_startup_role-${local.naming_suffix}"
  }
}

# IAM role

resource "aws_iam_role" "ec2_startup_role" {
    name = "ec2_startup_role-${var.naming_suffix}"

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
    Name = "ec2_startup_role-${local.naming_suffix}"
  }
}

# IAM role

resource "aws_iam_role" "ec2_shutdown_role" {
    name = "ec2_shutdown_role-${var.naming_suffix}"

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
    Name = "ec2_shutdown_role-${local.naming_suffix}"
  }
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

data "aws_iam_policy_document" "eventwatch_ec2_doc" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]

    resources = [
      "*",
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

resource "aws_iam_policy" "eventwatch_ec2_policy" {
  name   = "eventwatch_ec2_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.eventwatch_ec2_doc.json}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_logs_policy_attachment" {
    role     =   "${aws_iam_role.rds-shutdown_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_logs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_rds_policy_attachment" {
    role    =    "${aws_iam_role.rds-shutdown_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_rds_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_ec2_policy_attachment" {
  role       = "${aws_iam_role.ec2_startup_role.name}"
  policy_arn = "${aws_iam_policy.eventwatch_ec2_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_ec2shutdown_policy_attachment" {
    role     =   "${aws_iam_role.ec2_shutdown_role.name}"
    policy_arn = "${aws_iam_policy.eventwatch_ec2_policy.arn}"
}

# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_rds-shutdown" {
    name  =  "daily_rds-shutdown"
    description = "triggers daily RDS shutdown"
    schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "daily_rds_startup" {
    name  =  "daily_rds_startup"
    description = "triggers daily RDS startup"
    schedule_expression = "cron(30 6 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "daily_ec2_startup" {
  name                = "daily_ec2_startup"
  description         = "triggers daily ec2 startup"
  schedule_expression = "cron(0 7 ? * MON-FRI *)"
}

resource "aws_cloudwatch_event_rule" "daily_ec2_shutdown" {
    name  =  "daily_ec2_shutdown"
    description = "triggers daily ec2 shutdown"
    schedule_expression = "cron(0 18 ? * MON-FRI *)"
}


# Defines target for the rule - the Lambda function to trigger
# Points to the Lamda function

resource "aws_cloudwatch_event_target" "rds_lambda_target" {
    target_id = "rds-shutdown-function"
    rule      = "${aws_cloudwatch_event_rule.daily_rds-shutdown.name}"
    arn       = "${aws_lambda_function.rds-shutdown-function.arn}"
}

resource "aws_cloudwatch_event_target" "rds_lambda_startup_target" {
    target_id = "rds_startup-function"
    rule      = "${aws_cloudwatch_event_rule.daily_rds_startup.name}"
    arn       = "${aws_lambda_function.rds_startup-function.arn}"
}

resource "aws_cloudwatch_event_target" "ec2_lambda_target" {
  target_id = "ec2_startup-function"
  rule      = "${aws_cloudwatch_event_rule.daily_ec2_startup.name}"
  arn       = "${aws_lambda_function.ec2-startup-function.arn}"
}

resource "aws_cloudwatch_event_target" "ec2shutdown_lambda_target" {
  target_id = "ec2-shutdown-function"
  rule      = "${aws_cloudwatch_event_rule.daily_ec2_shutdown.name}"
  arn       = "${aws_lambda_function.ec2-shutdown-function.arn}"
}
