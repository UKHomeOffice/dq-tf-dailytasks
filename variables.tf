locals {
    naming_suffix = "${var.naming_suffix}"
    path_module = "${var.path_module != "unset" ? var.path_module : path.module}"
}

variable "path_module" {
   default = "unset"
}

variable "namespace" {
   default = "notprod"
}

variable "naming_suffix" {
   default = "apps-test-dq"
}

#### Test variables added
variable "cidr_block" {}
variable "public_subnet_cidr_block" {}
variable "ad_subnet_cidr_block" {}
variable "az" {}
variable "az2" {}
variable "adminpassword" {}
variable "ad_aws_ssm_document_name" {}
variable "ad_writer_instance_profile_name" {}
variable "haproxy_private_ip" {}
variable "haproxy_private_ip2" {}

