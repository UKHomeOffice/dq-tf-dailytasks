resource "aws_cloudwatch_event_target" "cleanup_snapshots" {
  rule = "${aws_cloudwatch_event_rule.cleanup_snapshots.name}"
  arn  = "${aws_lambda_function.cleanup_snapshots.arn}"

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
