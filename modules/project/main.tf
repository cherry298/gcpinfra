resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  org_id          = var.organization_id
  billing_account = var.billing_account
  labels          = var.labels
  deletion_policy = var.deletion_policy
  # Leave network behavior at the provider default for this minimal test.
  # Organization policy can suppress default network creation.
}

resource "google_project_service" "this" {
  for_each           = var.enabled_apis
  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}
