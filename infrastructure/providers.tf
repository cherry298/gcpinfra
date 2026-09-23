# ADC is supplied by google-github-actions/auth. No service-account key needed.
# Use an EXISTING project for the provider context, not the new project.
provider "google" {
  project = var.bootstrap_project_id
}
