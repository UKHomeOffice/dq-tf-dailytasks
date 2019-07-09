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
