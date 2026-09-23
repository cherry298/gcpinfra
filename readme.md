# GCP project creation using Terraform and existing GitHub OIDC

Create a new Google Cloud project directly under your organization using your existing Terraform service account and Workload Identity Federation (OIDC). No service-account key is needed. The existing OIDC pool, provider and Terraform account are not recreated.

## Repository layout

```text
Infrastructure/
  backend.tf
  main.tf
  outputs.tf
  providers.tf
  variables.tf
  versions.tf
  terraform.tfvars
  .terraform.lock.hcl
modules/
  project/
    main.tf
    variables.tf
    outputs.tf
  service-accounts/
    main.tf
    variables.tf
    outputs.tf
.github/
  workflows/
    terraform.yml
.gitignore
.terraform-version
README.md
VALIDATION.md
```

Copy the CONTENTS of this folder into the root of your GitHub repository, including the hidden `.github` folder. Use the repository and default branch already trusted by your OIDC configuration. The workflow is manual and only runs on the default branch.

## 1. Existing prerequisites

- An existing GCP project containing the Terraform service account and a working GitHub OIDC provider. The identity-pool project can be different.
- The GitHub identity must have `roles/iam.workloadIdentityUser` on the existing Terraform service account, and the provider's attribute condition must allow this repository and branch. This starter uses no GitHub environment; an existing subject restriction requiring an environment must be aligned with the workflow before use.
- The Terraform service account needs `roles/resourcemanager.projectCreator` on the target organization. It also needs permission to read/update the created project for Terraform refresh and labels. Project creators commonly receive Owner on the new project; if your organization prevents that, arrange scoped project-management access with your administrator. OIDC authentication alone does not grant project-creation permission.
- An EXISTING GCS state bucket in a bootstrap/admin project. Give the Terraform service account `roles/storage.objectAdmin` on this bucket; enable object versioning for recovery. Do not put this bucket in the new project or create it in this same state. Backend initialization occurs before project creation.
- Enable the required bootstrap APIs in advance: Cloud Resource Manager (`cloudresourcemanager.googleapis.com`), IAM Service Account Credentials (`iamcredentials.googleapis.com`) and Security Token Service (`sts.googleapis.com`) in the relevant bootstrap/identity projects. Existing working OIDC usually already has the identity APIs configured. Service Usage (`serviceusage.googleapis.com`) is needed when managing APIs.
- Your organization must permit project creation and have available project quota.

Additional access is needed only if you enable optional features:

| Feature | Existing Terraform service account access |
| --- | --- |
| Link billing | Billing Account User on the selected billing account and project billing-assignment permission (for example Project Billing Manager on the target project, or an inherited role that includes it) |
| Enable project APIs | Service Usage Admin on the new project, or equivalent inherited permissions |
| Create workload service accounts | Service Account Admin on the new project, plus permission to enable the IAM API |
| Delete test project | `resourcemanager.projects.delete` on the target project |

This code does not grant these prerequisites to itself. No organization-wide Owner role is required. If a quota-project/service-usage error explicitly names the bootstrap project, your administrator may also need to allow `serviceusage.services.use` there.

## 2. Edit Infrastructure/terraform.tfvars

Replace the three `REPLACE_WITH_...` values:

```hcl
bootstrap_project_id = "your-existing-admin-project"
organization_id      = "123456789012"
project_id           = "your-unique-oidc-test-12345"
project_name         = "Terraform OIDC Test"
```

Use the organization NUMBER without `organizations/`. The new project ID must be globally unique, 6-30 characters, lowercase, and cannot be reused even after a project is deleted. Values above are examples, not real account details.

For the minimal connection test, keep `billing_account = null`, `enabled_apis = []` and `service_accounts = {}`. This creates only the project and labels. An unbilled project cannot use services that require billing; organization policies can also impose extra requirements. The configuration leaves default-network behavior unchanged; a default VPC may exist unless your organization suppresses it. This is a connectivity test, not a hardened landing zone.

## 3. Add GitHub repository variables

Open **Settings > Secrets and variables > Actions > Variables > New repository variable**.

| Variable | Example / meaning |
| --- | --- |
| `GCP_BOOTSTRAP_PROJECT_ID` | `your-existing-admin-project`; same as `bootstrap_project_id` in tfvars |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/123456789012/locations/global/workloadIdentityPools/github-pool/providers/github-provider` |
| `GCP_TERRAFORM_SERVICE_ACCOUNT` | `terraform@your-existing-admin-project.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | Existing bucket name, without `gs://` |
| `TF_STATE_PREFIX` | `terraform/oidc-project-test` |

The provider path uses the PROJECT NUMBER hosting the workload identity pool, not the organization ID or project ID. These values are identifiers, not private keys. No JSON-key GitHub secret is needed. Use one unique state prefix for this deployment and keep it unchanged for future runs.

## 4. Run the test

1. Commit the files on the repository's default branch. Keep `.terraform.lock.hcl` committed.
2. Open **Actions > Terraform GCP OIDC Project Test > Run workflow**.
3. Choose `plan` first. A successful token-exchange step proves OIDC works; a successful plan previews changes but does NOT prove project-creation permission.
4. Run again with `apply`. This creates a fresh plan and applies that exact plan in the same job. It creates or updates real resources without another approval prompt.
5. Check the final step: it prints project ID, project number, lifecycle state and parent organization. An applied project with the expected parent completes the connection and authorization test.
6. Run `plan` again. It should show no changes if nothing has drifted.

State is stored in GCS, with Terraform locking and workflow concurrency. Do not change the bucket/prefix or discard state between runs. The workflow does not upload plans, credentials or state as GitHub artifacts.

## 5. Optional workload service accounts

Replace `service_accounts = {}` in tfvars with:

```hcl
service_accounts = {
  oidc-test-workload = {
    display_name = "OIDC Test Workload"
    description  = "Test workload account"
  }
}
```

The separate module enables `iam.googleapis.com` and creates the requested accounts. It creates no keys and grants no roles. Do not also put `iam.googleapis.com` in `enabled_apis` while using this module, because one API must not be owned by two Terraform resources. These accounts are separate from the existing Terraform OIDC service account.

## 6. Local commands (optional)

Use Terraform 1.10.5. Supply ADC through an approved login, impersonation or federation flow first. GitHub's OIDC credential file exists only during the workflow; local user ADC is a different authentication test.

```bash
cd Infrastructure
terraform init -backend-config="bucket=YOUR_EXISTING_STATE_BUCKET" -backend-config="prefix=terraform/oidc-project-test"
terraform fmt -check -recursive ..
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Do not set `credentials` or a second `impersonate_service_account` in the provider for GitHub execution: the auth action already supplies ADC impersonating the existing account.

## Cleanup

The project starts with `deletion_policy = "PREVENT"`. To intentionally remove this test project, change it to `DELETE` and apply that configuration FIRST so state records the change. Then, with authorized ADC and the same GCS backend, run `terraform plan -destroy -out=destroy.tfplan`, inspect the plan, and run `terraform apply destroy.tfplan`. This deletes the entire test project and any resources inside it. There is deliberately no destroy option in the GitHub workflow. APIs configured here use `disable_on_destroy = false`; project deletion removes the project regardless. Leave the existing state bucket and OIDC setup intact.

## Troubleshooting

| Failure | Meaning / next check |
| --- | --- |
| OIDC credential exchange fails | Existing provider path, audience, repository/branch condition or service-account trust binding is wrong |
| Backend init returns 403/404 | Existing state bucket name or bucket object permissions are wrong |
| Project create returns 403 | Organization Project Creator permission, policy restrictions or project quota |
| Billing error | Billing account state and billing-assignment permissions |
| API/service-account creation fails | Optional-feature permissions or API enablement requirements |
| Project already exists | Choose a globally unique ID; if an earlier create succeeded but state was lost, investigate and import that intended project instead of blindly recreating it |
| Workflow job skipped | Run from the repository default branch |
| Credentials expire in a long operation | Re-run with fresh OIDC credentials and inspect persisted state; do not delete state |

## Versions and official references

This starter pins Terraform 1.10.5 and Google provider 6.50.0 for repeatability; these are deliberate pins, not a claim of latest releases. Upgrade and regenerate the lock file together when needed. GitHub actions are referenced by supported major tags; your organization can pin reviewed commit SHAs.

- https://github.com/google-github-actions/auth
- https://github.com/google-github-actions/setup-gcloud
- https://registry.terraform.io/providers/hashicorp/google/6.50.0/docs/resources/google_project
- https://registry.terraform.io/providers/hashicorp/google/6.50.0/docs/resources/google_service_account
- https://developer.hashicorp.com/terraform/language/backend/gcs
- https://cloud.google.com/resource-manager/docs/creating-managing-projects
