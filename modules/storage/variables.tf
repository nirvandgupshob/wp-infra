variable "name_prefix" {
  description = "Resource name prefix"
  type        = string
}

variable "subnet_ids" {
  description = "Mount target subnets, one per zone"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Subnets in at least two zones are required, otherwise one zone failure cuts off the file system."
  }
}

variable "security_group_ids" {
  description = "EFS security groups"
  type        = list(string)
}

variable "posix_uid" {
  description = "Owner uid for files; 33 is www-data"
  type        = number
  default     = 33
}

variable "posix_gid" {
  description = "Owner gid for files"
  type        = number
  default     = 33
}

variable "root_directory" {
  description = "Access point root directory, not /"
  type        = string
  default     = "/uploads"

  validation {
    condition     = var.root_directory != "/" && startswith(var.root_directory, "/")
    error_message = "Must start with a slash and must not be the root."
  }
}

variable "transition_to_ia" {
  description = "Transition to infrequent access storage"
  type        = string
  default     = "AFTER_30_DAYS"
}

variable "enable_backup" {
  description = "Daily backups"
  type        = bool
  default     = true
}

variable "enforce_tls" {
  description = "Require encryption in transit"
  type        = bool
  default     = true
}
