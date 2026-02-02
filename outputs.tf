locals {
  key_vault_references = {
    for secret in nonsensitive(var.app_secrets) :
    secret.name => "@Microsoft.KeyVault(SecretUri=${local.key_vault.vault_uri}secrets/${secret.name}/)"
  }
}

output "key_vault" {
  value = local.key_vault
}

output "app_settings_bindings" {
  value = length(local.app_secret_bindings) > 0 ? {
    for app_setting_key, secret_name in local.app_secret_bindings :
    app_setting_key => local.key_vault_references[secret_name]
  } : {}
}

output "key_vault_references" {
  value = local.key_vault_references
}