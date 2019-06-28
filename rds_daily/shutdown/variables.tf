locals {
    path_module = "${var.path_module != "unset" ? var.path_module : path.module}"
}

variable "path_module" {
   default = "unset"
}
