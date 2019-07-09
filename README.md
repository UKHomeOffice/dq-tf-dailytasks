# dq-tf-dailytasks

This Terraform module provides configuration for Cloudwatch triggered Lambda daily EC2 and RDS Instances shutdown and startup.

# Content overview
This repo controls the deployment of Lambda Cloudwatch scheduled cost savings tasks.

It consists of the following core elements:

# main.tf
  This file comprises of the following resources
  - AWS archive file
  - AWS Lambda Function
  - AWS IAM Role
  - AWS IAM Policy Documents
  - AWS IAM Role Attachments
  - AWS Cloudwatch Event Rules
  - AWS Cloudwatch Event Target

# variables.tf
  Holds input data for resources within this repo.

# tests/e2e_test.py
  Code and resource tester with mock data. It can be expanded by adding further definitions to the unit.

# Lambda Function Package
   Python Boto3 scripts required by Lambda.
