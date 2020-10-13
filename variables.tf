locals {
  naming_suffix = var.naming_suffix
  path_module   = var.path_module != "unset" ? var.path_module : path.module
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

variable "region" {
  default = "eu-west-2"
}
