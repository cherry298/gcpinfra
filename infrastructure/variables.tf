variable "bootstrap_project_id" {
  description = "Existing project hosting your Terraform service account; never the project being created."
  type        = string
}

variable "organization_id" {
  description = "Numeric organization ID, without organizations/."
  type        = string
  validation {
    condition     = can(regex("^[0-9]+$", var.organization_id))
    error_message = "Use only the numeric organization ID."
  }
}

variable "project_id" {
  description = "New globally unique project ID, 6-30 characters."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Use 6-30 lowercase letters, numbers or hyphens; start with a letter and end with a letter or number."
  }
}

variable "project_name" {
  description = "Display name for the new project."
  type        = string
  validation {
    condition     = length(var.project_name) >= 4 && length(var.project_name) <= 30
    error_message = "Project display name must contain 4-30 characters."
  }
}

variable "billing_account" {
  description = "Optional billing account ID (XXXXXX-XXXXXX-XXXXXX); null leaves billing unlinked."
  type        = string
  default     = null
  validation {
    condition     = var.billing_account == null ? true : can(regex("^[A-Fa-f0-9]{6}-[A-Fa-f0-9]{6}-[A-Fa-f0-9]{6}$", var.billing_account))
    error_message = "Use a billing account ID in XXXXXX-XXXXXX-XXXXXX format, or null."
  }
}

variable "labels" {
  description = "Project labels."
  type        = map(string)
  default     = {}
}

variable "enabled_apis" {
  description = "Optional APIs to enable after project creation."
  type        = set(string)
  default     = []
}

variable "deletion_policy" {
  description = "PREVENT protects the project from deletion; DELETE allows explicit cleanup."
  type        = string
  default     = "PREVENT"
  validation {
    condition     = contains(["PREVENT", "DELETE"], var.deletion_policy)
    error_message = "Choose PREVENT or DELETE."
  }
}

variable "service_accounts" {
  description = "Optional workload service accounts, keyed by account ID. No keys or role grants are created."
  type = map(object({
    display_name = string
    description  = optional(string, "Managed by Terraform")
  }))
  default = {}
  validation {
    condition     = alltrue([for id in keys(var.service_accounts) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", id))])
    error_message = "Service account IDs must be 6-30 characters, begin with a lowercase letter and end with a letter or number."
  }
}
