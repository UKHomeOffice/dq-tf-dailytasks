resource "aws_cloudwatch_event_target" "cleanup_snapshots" {
  rule = aws_cloudwatch_event_rule.cleanup_snapshots.name
  arn  = aws_lambda_function.cleanup_snapshots.arn

  input = <<DOC
  {
  "res": "Encrypted"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "cleanup_snapshots" {
  name                = "cleanup_unencrypted_snapshots"
  description         = "Delete unencrypted snapshots for EC2 Instances"
  schedule_expression = "cron(0 09 * * ? *)"
}

resource "aws_cloudwatch_event_target" "rds_shutdown" {
  count = var.namespace == "prod" ? "0" : "1"
  rule  = aws_cloudwatch_event_rule.rds_shutdown[0].name
  arn   = aws_lambda_function.rds_shutdown[0].arn

  input = <<DOC
  {
    "instances": [
    ],
    "action": "stop"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "rds_shutdown" {
  count               = var.namespace == "prod" ? "0" : "1"
  name                = "daily_rds_shutdown"
  description         = "Shutdown RDS Instances in notprod evenings and weekend"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
  is_enabled          = "true"
}

resource "aws_cloudwatch_event_target" "rds_startup" {
  count = var.namespace == "prod" ? "0" : "1"
  rule  = aws_cloudwatch_event_rule.rds_startup[0].name
  arn   = aws_lambda_function.rds_startup[0].arn

  input = <<DOC
  {
    "instances": [
    ],
    "action": "start"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "rds_startup" {
  count               = var.namespace == "prod" ? "0" : "1"
  name                = "daily_rds_startup"
  description         = "Startup RDS Instances in notprod mornings weekday"
  schedule_expression = "cron(00 9 ? * MON-FRI *)"
  is_enabled          = "true"
}

resource "aws_cloudwatch_event_target" "ec2_shutdown" {
  count = var.namespace == "prod" ? "0" : "1"
  rule  = aws_cloudwatch_event_rule.ec2_shutdown[0].name
  arn   = aws_lambda_function.ec2_shutdown[0].arn

  input = <<DOC
  {
    "Name" : "running"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "ec2_shutdown" {
  count               = var.namespace == "prod" ? "0" : "1"
  name                = "daily_ec2_shutdown"
  description         = "Shutdown EC2 Instances in notprod evenings and weekends"
  schedule_expression = "cron(0 18 ? * MON-FRI *)"
  is_enabled          = "true"
}

resource "aws_cloudwatch_event_target" "ec2_startup" {
  count = var.namespace == "prod" ? "0" : "1"
  rule  = aws_cloudwatch_event_rule.ec2_startup[0].name
  arn   = aws_lambda_function.ec2_startup[0].arn

  input = <<DOC
  {
    "Name" : "stopped"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "ec2_startup" {
  count               = var.namespace == "prod" ? "0" : "1"
  name                = "daily_ec2_startup"
  description         = "Startup EC2 Instances in notprod mornings weekday"
  schedule_expression = "cron(00 9 ? * MON-FRI *)"
  is_enabled          = "true"
}

resource "aws_cloudwatch_event_target" "monitor_stage" {
  count = var.namespace == "prod" ? "1" : "0"
  rule  = aws_cloudwatch_event_rule.monitor_stage[0].name
  arn   = aws_lambda_function.monitor_stage[0].arn

  input = <<DOC
  {
    "Name" : "stopped"
  }
DOC

}

resource "aws_cloudwatch_event_rule" "monitor_stage" {
  count               = var.namespace == "prod" ? "1" : "0"
  name                = "daily_monitor_stage"
  description         = "Daily Check if staging EC2 and RDS are running"
  schedule_expression = "cron(00 8 ? * MON-FRI *)"
  is_enabled          = false
}

resource "aws_lambda_permission" "allow_monitor_stage_to_run_by_cw_rule" {
  count         = var.namespace == "prod" ? "1" : "0"
  action        = "lambda:InvokeFunction"
  function_name = "${var.pipeline_name}-${var.namespace}-monitor-stage"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitor_stage[0].arn
}
