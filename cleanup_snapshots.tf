data "archive_file" "cleanup_snapshots_zip" {
  type        = "zip"
  source_file = "${local.path_module}/lambda/code/cleanup_snapshots.py"
  output_path = "${local.path_module}/lambda/package/cleanup_snapshots.zip"
}

resource "aws_lambda_function" "cleanup_snapshots" {
  filename         = "${path.module}/lambda/package/cleanup_snapshots.zip"
  function_name    = "${var.pipeline_name}-${var.namespace}-cleanup-snapshots"
  role             = aws_iam_role.cleanup_snapshots.arn
  handler          = "cleanup_snapshots.lambda_handler"
  source_code_hash = data.archive_file.cleanup_snapshots_zip.output_base64sha256
  runtime          = "python3.7"
  timeout          = "900"
  memory_size      = "128"

  tags = {
    Name = "cleanup-ec2-snapshots-${local.naming_suffix}"
  }

  lifecycle {
    ignore_changes = [
      filename,
      last_modified,
      source_code_hash,
    ]
  }
}

resource "aws_iam_role" "cleanup_snapshots" {
  name = "${var.pipeline_name}-${var.namespace}-cleanup-snapshots"

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
    Name = "cleanup-ec2-snapshots-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "cleanup_snapshots" {
  name        = "${var.pipeline_name}-cleanup-ec2-snapshots"
  path        = "/"
  description = "IAM policy for describing snapshots"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ec2:DeregisterImage",
                "ec2:DeleteSnapshot",
                "ec2:ModifySnapshotAttribute",
                "ec2:DescribeSnapshots"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "cleanup_snapshots" {
  role       = aws_iam_role.cleanup_snapshots.name
  policy_arn = aws_iam_policy.cleanup_snapshots.arn
}

resource "aws_cloudwatch_log_group" "lambda_cleanup_snapshots" {
  name              = "/aws/lambda/${aws_lambda_function.cleanup_snapshots.function_name}"
  retention_in_days = 14

  tags = {
    Name = "cleanup-ec2-snapshots-${local.naming_suffix}"
  }
}

resource "aws_iam_policy" "lambda_cleanup_snapshots_logging" {
  name        = "${var.pipeline_name}-cleanup-ec2-snapshots-logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "${aws_cloudwatch_log_group.lambda_cleanup_snapshots.arn}",
        "${aws_cloudwatch_log_group.lambda_cleanup_snapshots.arn}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_cleanup_snapshots_logs" {
  role       = aws_iam_role.cleanup_snapshots.name
  policy_arn = aws_iam_policy.lambda_cleanup_snapshots_logging.arn
}
