module "project" {
  source          = "../modules/project"
  project_id      = var.project_id
  project_name    = var.project_name
  organization_id = var.organization_id
  billing_account = var.billing_account
  labels          = var.labels
  enabled_apis    = var.enabled_apis
  deletion_policy = var.deletion_policy
}

# This creates a separate workload service account, not the existing OIDC account.
module "service_accounts" {
  source           = "../modules/service-accounts"
  project_id       = module.project.project_id
  service_accounts = var.service_accounts
  depends_on       = [module.project]
}
