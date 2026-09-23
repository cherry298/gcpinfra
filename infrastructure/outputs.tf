output "project_id" {
  description = "Created project ID."
  value       = module.project.project_id
}
output "project_number" {
  description = "Google-assigned project number."
  value       = module.project.project_number
}
output "organization_id" {
  description = "Parent organization ID."
  value       = var.organization_id
}
output "service_account_emails" {
  description = "Optional workload service account emails."
  value       = module.service_accounts.emails
}
