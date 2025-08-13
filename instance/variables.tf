variable "arch" {
  type = string

  validation {
    condition     = contains(keys(local.shape), var.arch)
    error_message = "${var.arch} not one of ${join(",", keys(local.shape))}"
  }
}

variable "compartment_ocid" {
  type = string
}

variable "subnet_ocid" {
  type = string
}

variable "image_ocids" {
  type = object({
    aarch64 = string
    x86_64  = string
  })
}

variable "availability_domains" {
  type = map(string)
}

variable "ansible_groups" {
  type = set(string)
}
