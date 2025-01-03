## HOLIDAY SCHEDULE FUNCTION, UNCOMMENT DURING DOWNTIME

# data "archive_file" "rule_disable_zip" {
#   type        = "zip"
#   source_file = "${local.path_module}/lambda/code/rule_disable.py"
#   output_path = "${local.path_module}/lambda/package/rule_disable.zip"
# }

# resource "aws_lambda_function" "rule_disable" {
#   count            = var.namespace == "prod" ? "0" : "1"
#   filename         = "${path.module}/lambda/package/rule_disable.zip"
#   function_name    = "${var.pipeline_name}-${var.namespace}-rule-disable"
#   role             = aws_iam_role.rule_disable[0].arn
#   handler          = "rule_disable.lambda_handler"
#   source_code_hash = data.archive_file.rule_disable_zip.output_base64sha256
#   runtime          = "python3.9"
#   timeout          = "900"
#   memory_size      = "128"
#   environment {
#     variables = {
#       RULE_NAMES = "daily_ec2_shutdown,daily_ec2_startup,daily_rds_shutdown,daily_rds_startup"
#     }
#   }

#   tags = {
#     Name = "rule-disable-${local.naming_suffix}"
#   }

#   #   lifecycle {
#   #     ignore_changes = [
#   #       filename,
#   #       last_modified,
#   #       source_code_hash,
#   #     ]
#   #   }
# }

# resource "aws_iam_role" "rule_disable" {
#   count = var.namespace == "prod" ? "0" : "1"
#   name  = "${var.pipeline_name}-${var.namespace}-rule-disable"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF


#   tags = {
#     Name = "rule-disable-${local.naming_suffix}"
#   }
# }

# resource "aws_iam_policy" "rule_disable" {
#   count       = var.namespace == "prod" ? "0" : "1"
#   name        = "${var.pipeline_name}-rule-disable"
#   path        = "/"
#   description = "IAM policy for disabling rules"

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "",
#             "Effect": "Allow",
#             "Action": [
#                 "events:DisableRule",
#                 "events:DescribeRule"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF

# }

# resource "aws_iam_role_policy_attachment" "rule_disable" {
#   count      = var.namespace == "prod" ? "0" : "1"
#   role       = aws_iam_role.rule_disable[0].name
#   policy_arn = aws_iam_policy.rule_disable[0].arn
# }

# resource "aws_cloudwatch_event_target" "rule_disable" {
#   count = var.namespace == "prod" ? "0" : "1"
#   rule  = aws_cloudwatch_event_rule.rule_disable[0].name
#   arn   = aws_lambda_function.rule_disable[0].arn


# }

# resource "aws_cloudwatch_event_rule" "rule_disable" {
#   count               = var.namespace == "prod" ? "0" : "1"
#   name                = "holiday_eventrule_disable"
#   description         = "Disable daily startup and shutdown for ec2 and RDS"
#   schedule_expression = "cron(0 18 20 12 ? 2024)"
#   is_enabled          = "true"
# }

# resource "aws_cloudwatch_log_group" "lambda_rule_disable" {
#   count             = var.namespace == "prod" ? "0" : "1"
#   name              = "/aws/lambda/${aws_lambda_function.rule_disable[0].function_name}"
#   retention_in_days = 14

#   tags = {
#     Name = "rule-disable-${local.naming_suffix}"
#   }
# }

# resource "aws_iam_policy" "lambda_rule_disable_logging" {
#   count       = var.namespace == "prod" ? "0" : "1"
#   name        = "${var.pipeline_name}-rule-disable-logging"
#   path        = "/"
#   description = "IAM policy for logging from a lambda"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "cloudwatch:GetMetricStatistics",
#         "logs:DescribeLogStreams",
#         "logs:GetLogEvents",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents"
#       ],
#       "Resource": [
#         "${aws_cloudwatch_log_group.lambda_rule_disable[0].arn}",
#         "${aws_cloudwatch_log_group.lambda_rule_disable[0].arn}/*"
#       ],
#       "Effect": "Allow"
#     }
#   ]
# }
# EOF

# }

# resource "aws_iam_role_policy_attachment" "lambda_rule_disable_logs" {
#   count      = var.namespace == "prod" ? "0" : "1"
#   role       = aws_iam_role.rule_disable[0].name
#   policy_arn = aws_iam_policy.lambda_rule_disable_logging[0].arn
# }
