resource "google_project_service" "iam" {
  count              = length(var.service_accounts) > 0 ? 1 : 0
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "this" {
  for_each     = var.service_accounts
  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  depends_on   = [google_project_service.iam]
}
