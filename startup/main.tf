provider "aws" {
  region = "eu-west-2"
}

<<<<<<< HEAD
# path for zipped file
=======
>>>>>>> 2575203... startup configuration file added
data "archive_file" "ecstartzip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/ec2-startup.py"
  output_path = "${local.path_module}/lambda/package/ec2-startup.zip"
}

resource "aws_lambda_function" "ec2-startup-function" {
  function_name    = "ec2_daily_startup"
  handler          = "ec2-startup.lambda_handler"
  runtime          = "python3.7"
  role             = "${aws_iam_role.ec2_startup_role.arn}"
  filename         = "${path.module}/lambda/package/ec2-startup.zip"
  memory_size      = 128
  timeout          = 10
  source_code_hash = "${data.archive_file.ecstartzip.output_base64sha256}"
}

# IAM role

resource "aws_iam_role" "ec2_startup_role" {
  name = "ec2_startup_role"

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
      "logs:GetLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
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
  name   = "eventwatch_logs_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.eventwatch_logs_doc.json}"
}

resource "aws_iam_policy" "eventwatch_ec2_policy" {
  name   = "eventwatch_ec2_policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.eventwatch_ec2_doc.json}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_logs_policy_attachment" {
  role       = "${aws_iam_role.ec2_startup_role.name}"
  policy_arn = "${aws_iam_policy.eventwatch_logs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_ec2_policy_attachment" {
  role       = "${aws_iam_role.ec2_startup_role.name}"
  policy_arn = "${aws_iam_policy.eventwatch_ec2_policy.arn}"
}

# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_ec2_startup" {
  name                = "daily_ec2_startup"
  description         = "triggers daily ec2 shutdown"
  schedule_expression = "cron(5 14 ? * MON-FRI *)"
}

# Defines target for the rule - the Lambda function to trigger
# Points to the Lamda function

resource "aws_cloudwatch_event_target" "ec2_lambda_target" {
  target_id = "ec2_shutdown2"
  rule      = "${aws_cloudwatch_event_rule.daily_ec2_startup.name}"
  arn       = "${aws_lambda_function.ec2-startup-function.arn}"
}
