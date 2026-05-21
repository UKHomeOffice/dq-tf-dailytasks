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

variable "ec2_prod_scheduled_instance_names" {
  type        = list(string)
  description = "Name tags for prod instances to start"
  default = [
    "ec2-staging-internal-tableau-apps-prod-dq",
    "ec2-staging-ext-tableau-linux-apps-prod-dq",
    "tab-dep-1-tableau-ops-prod-dq",
  ]
}