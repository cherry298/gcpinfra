# Validation performed

- Terraform CLI: 1.10.5, linux_amd64.
- `terraform init -backend=false -input=false`: passed. Downloaded Google provider 6.50.0, verified its HashiCorp signature and generated the included dependency lock file.
- `terraform fmt -check -recursive`: passed for the root configuration and modules; this also parsed the HCL syntax.
- GitHub Actions YAML parsing: passed.
- Every embedded workflow Bash script checked with `bash -n`: passed.
- `terraform validate`: attempted, but could not complete. The execution environment prevents the provider process from opening its Unix socket (`socket: operation not permitted`). Provider-schema validation therefore remains to be completed in GitHub Actions or your local environment.
- Live OIDC, GCS backend, plan and apply: not run, because your actual identifiers and credentials were not supplied. No cloud resources were created.

The included workflow runs `terraform validate` before plan/apply. Fill in the tfvars placeholders and GitHub variables before use. The package contains source and the lock file; it excludes downloaded providers, credentials, state and plan files.
