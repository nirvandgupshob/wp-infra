variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "zone_name" {
  description = "Existing hosted zone; the module does not create it"
  type        = string
}

variable "certificate_domain_names" {
  description = "Certificate domain names, the first one is primary"
  type        = list(string)

  validation {
    condition     = length(var.certificate_domain_names) > 0
    error_message = "At least one domain name is required."
  }
}

variable "validation_timeout" {
  description = "Certificate validation timeout"
  type        = string
  default     = "10m"
}
