locals {
  naming_suffix = "${var.naming_suffix}"
  path_module   = "${var.path_module != "unset" ? var.path_module : path.module}"
}

variable "path_module" {
  default = "unset"
}

variable "namespace" {
  default = "test"
}

variable "naming_suffix" {
  default = "apps-test-dq"
}

variable "pipeline_name" {
  default = "aws-maintenance"
}

variable "pipeline_count" {
  default = 1
}

variable "lambda_subnet" {
  default = "subnet-05f088f2a4a2fd968"
}

variable "lambda_subnet_az2" {
  default = "subnet-04e1ded8159dbc3ee"
}

variable "lambda_sgrp" {
  default = "sg-08a996ab577bdb8aa"
}
