provider "aws" {
  region  =   "eu-west-2"
}


data "archive_file" "ecshutzip" {
  type   =  "zip"
  source_file = "${local.path_module}/lambda/code/ec2-shutdown.py"
  output_path = "${local.path_module}/lambda/package/ec2-shutdown.zip"
}


resource "aws_lambda_function" "ec2-shutdown-function" {
    function_name = "ec2_daily_shutdown"
    handler ="ec2-shutdown.lambda_handler"
    runtime = "python3.7"
    role = "${aws_iam_role.ec2_shutdown_testrole.arn}"
    filename = "${path.module}/lambda/package/ec2-shutdown.zip"
    memory_size = 128
    timeout = "10"
    source_code_hash = "${data.archive_file.ecshutzip.output_base64sha256}"
}

# IAM role

resource "aws_iam_role" "ec2_shutdown_testrole" {
    name = "ec2_shutdown_testrole"

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

data "aws_iam_policy_document" "eventwatch_ec2_doc" {
    statement {
        actions = [
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ec2:StartInstances",
            "ec2:StopInstances"
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

resource "aws_iam_policy" "eventwatch_ec2_policy" {
    name = "eventwatch_ec2_policy"
    path = "/"
    policy = "${data.aws_iam_policy_document.eventwatch_ec2_doc.json}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_logs_policy_attachment" {
    role     =   "${aws_iam_role.ec2_shutdown_testrole.name}"
    policy_arn = "${aws_iam_policy.eventwatch_logs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eventwatch_ec2_policy_attachment" {
    role    =    "${aws_iam_role.ec2_shutdown_testrole.name}"
    policy_arn = "${aws_iam_policy.eventwatch_ec2_policy.arn}"
}


# Creates CloudWatch Event Rule - triggers the Lambda function

resource "aws_cloudwatch_event_rule" "daily_ec2_shutdown" {
    name  =  "daily_ec2_shutdown"
    description = "triggers daily ec2 shutdown"
    schedule_expression = "cron(0 18 ? * MON-FRI *)"
}

# Defines target for the rule - the Lambda function to trigger
# Points to the Lamda function

resource "aws_cloudwatch_event_target" "ec2_lambda_target" {
    target_id = "ec2-shutdown-function"
    rule      = "${aws_cloudwatch_event_rule.daily_ec2_shutdown.name}"
    arn       = "${aws_lambda_function.ec2-shutdown-function.arn}"
}
                               
