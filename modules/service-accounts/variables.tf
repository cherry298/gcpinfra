variable "project_id" {
  type = string
}
variable "service_accounts" {
  type = map(object({
    display_name = string
    description  = optional(string, "Managed by Terraform")
  }))
  default = {}
}
