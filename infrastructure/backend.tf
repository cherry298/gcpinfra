# The bucket must already exist outside the project being created.
# GitHub Actions supplies bucket and prefix through terraform init.
terraform {
  backend "gcs" {}
}
