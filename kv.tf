locals {
  create_kv = length(var.app_secrets) > 0

  key_vault = try(data.azurerm_key_vault.existing_vault[0], azurerm_key_vault.vault[0], null)

  needs_kv_role = length(local.app_secret_bindings) > 0
}

data "azurerm_resource_group" "existing_rg" {
  name = var.key_vault_settings.rg_name
}

resource "azurerm_key_vault" "vault" {
  count = local.create_kv && !var.key_vault_settings.externally_created ? 1 : 0

  name                = var.key_vault_settings.name
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_settings.sku

  rbac_authorization_enabled = true
  purge_protection_enabled   = var.key_vault_settings.purge_protection_enabled
  soft_delete_retention_days = var.key_vault_settings.soft_delete_retention_days

  tags = var.key_vault_settings.tags
}

resource "azurerm_role_assignment" "webapp_kv_reader" {
  count = local.needs_kv_role ? 1 : 0

  scope                = local.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.managed_identity_principal_id
}

data "azurerm_key_vault" "existing_vault" {
  count = var.key_vault_settings.externally_created ? 1 : 0

  name                = var.key_vault_settings.name
  resource_group_name = var.key_vault_settings.rg_name
}

resource "azurerm_key_vault_secret" "app_secrets" {
  for_each = local.app_secrets_by_name

  name         = each.key
  value        = each.value.initial_value != null ? each.value.initial_value : ""
  key_vault_id = local.key_vault.id
  tags         = nonsensitive(each.value.tags)

  lifecycle {
    ignore_changes = [value]
  }
}
