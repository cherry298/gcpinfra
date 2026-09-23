# Replace all REPLACE values before running.
bootstrap_project_id = "project-9ff6caa9-3d73-4237-95b"
organization_id      = "785614744194"
project_id           = "bootstrap-test-1234"
project_name         = "bootstrap-terraform"

# Leave null for a project-only authentication/authorization test.
billing_account = null

labels = {
  environment = "test"
  managed_by  = "terraform"
  purpose     = "oidc-test"
}

enabled_apis     = []
service_accounts = {}
deletion_policy  = "PREVENT"

# Optional: create a workload service account inside the new project.
# service_accounts = {
#   oidc-test-workload = {
#     display_name = "OIDC Test Workload"
#     description  = "Optional workload account; no keys or IAM grants"
#   }
# }
# Replace service_accounts = {} above; do not define it twice.
# The module enables iam.googleapis.com automatically when accounts are requested.
