locals {
  naming_suffix = var.naming_suffix
  path_module   = var.path_module != "unset" ? var.path_module : path.module
}

variable "region" {
  default = "eu-west-2"
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
  default = "daily-tasks"
}

variable "kms_key_s3" {
  description = "The ARN of the KMS key that is used to encrypt HTTPD config bucket objects"
  default     = "arn:aws:kms:eu-west-2:483846886818:key/c3884750-ad4e-4654-a63b-f5009dbc2c59"
}

variable "pipeline_count" {
  default = 1
}

variable "account_id" {
  type = map(string)
  default = {
    "test"    = "797728447925"
    "notprod" = "483846886818"
    "prod"    = "337779336338"
  }
}
