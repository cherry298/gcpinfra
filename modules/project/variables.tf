variable "project_id" {
  type = string
}
variable "project_name" {
  type = string
}
variable "organization_id" {
  type = string
}
variable "billing_account" {
  type    = string
  default = null
}
variable "labels" {
  type    = map(string)
  default = {}
}
variable "enabled_apis" {
  type    = set(string)
  default = []
}
variable "deletion_policy" {
  type    = string
  default = "PREVENT"
}
