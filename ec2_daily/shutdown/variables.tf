variable "naming_suffix" {
   default = "notprod"
}

variable "path_module" {
   default = "unset"
}

locals {
   path_module =  "${var.path_module != "unset" ? var.path_module : path.module}"
}
