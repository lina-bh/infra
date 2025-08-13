variable "compartment_ocid" {
  type = string
}

variable "tailnet" {
  type = string
}

variable "alpine_images" {
  type = object({ aarch64 = string, x86_64 = string })
}
