variable "region" { default = "ap-south-1" }
variable "name" {
  default = "devops-portfolio"
  validation {
    condition = can(regex("^[a-z][a-z0-9-]{2,19}$", var.name))
    error_message = "Use 3-20 lowercase letters, digits or hyphens; start with a letter."
  }
}
variable "admin_cidr" {
  type = string
  description = "Your public IPv4 address with /32, for SSH only"
  validation {
    condition = can(cidrnetmask(var.admin_cidr)) && can(regex("/32$", var.admin_cidr))
    error_message = "Use a single IPv4 address with /32."
  }
}
variable "key_name" { type = string }
variable "instance_type" { default = "t3.micro" }
