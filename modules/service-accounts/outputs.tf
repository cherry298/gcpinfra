output "emails" {
  value = { for id, account in google_service_account.this : id => account.email }
}
