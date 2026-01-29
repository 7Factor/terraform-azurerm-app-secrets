# terraform-azurerm-app-secrets

A lightweight Terraform module for managing Azure Key Vault secrets for your applications, with optional app setting bindings via Key Vault references and RBAC-based access.

What you get:
- Azure Key Vault (created or reused), RBAC-enabled
- Managed Key Vault secrets with initial seeding and lifecycle protections
- Optional app settings bindings using Key Vault reference URIs
- Role assignment for managed identities (Key Vault Secrets User)
- Configurable SKU, purge protection, soft-delete retention, and tags

## Why this module?

Manage application secrets centrally and consistently:
- Declarative secret creation with optional initial values
- Safe lifecycle: ignore value drift to keep CI runs stable while allowing rotation out-of-band
- Works with existing Key Vaults or creates a new one with sensible defaults
- Simple integration pattern for app settings using Key Vault references

## Usage

Basic example (in need of a Key Vault instance):
```hcl-terraform
module "app_secrets" {
  source  = "7Factor/app-secrets/azurerm"
  version = ">= 1"

  app_secrets = [
    {
      name           = "Db-ConnectionString"
      initial_value  = "sample"   # seed only; subsequent value changes ignored by Terraform
      app_setting    = "ConnectionStrings__Database"  # optional: bind via KV reference
    },
    {
      name        = "Api-Key"
      app_setting = "MyApi__Key"
    },
    {
      name = "Unbound-Secret"     # created in KV, but not bound to an app setting
    }
  ]

  # This example uses a user-assigned identity, but you should also be able to use a system-assigned identity
  managed_identity_principal_id = azurerm_user_assigned_identity.my_web_app.principal_id

  key_vault_settings = {
    name    = "kv-myapp-dev" # A keyvault instance with this name will be created
    rg_name = "rg-myapp-dev" # A resource group with this name must already exist
    tags    = {
      environment = "dev"
    }
  }
}
```

Basic example (bringing your own Key Vault instance):
```hcl-terraform
module "app_secrets" {
  source  = "7Factor/app-secrets/azurerm"
  version = ">= 1"

  app_secrets = [
    {
      name           = "Db-ConnectionString"
      initial_value  = "sample"   # seed only; subsequent value changes ignored by Terraform
      app_setting    = "ConnectionStrings__Database"  # optional: bind via KV reference
    },
    {
      name        = "Api-Key"
      app_setting = "MyApi__Key"
    },
    {
      name = "Unbound-Secret"     # created in KV, but not bound to an app setting
    }
  ]

  # This example uses a user-assigned identity, but you should also be able to use a system-assigned identity
  managed_identity_principal_id = azurerm_user_assigned_identity.my_web_app.principal_id

  key_vault_settings = {
    externally_created = true
    name               = "kv-myapp-dev" # A keyvault instance with this name must already exist, because `externally_created` is true
    rg_name            = "rg-myapp-dev" # A resource group with this name must already exist
    tags               = {
      environment = "dev"
    }
  }
}
```

After apply:
- The module creates (or reuses) a Key Vault with RBAC authorization.
- Declared secrets are created. If `initial_value` is provided, it seeds the secret once; further changes to secret values are ignored by Terraform (rotate via Portal/CLI/CI).
- If app_setting is provided, an app setting binding string is generated using a non-versioned Key Vault reference URI: `@Microsoft.KeyVault(SecretUri=<vault_uri>secrets/<secret_name>/)`
- Managed identity listed in managed_identity_principal_id is granted the Key Vault Secrets User role to read secrets.

## Inputs

### Required

- **key_vault_settings** (object, required)
  - **name** (string, required)
  - **rg_name** (string, required)
  - _externally_created_ (bool, default: null)
  - _sku_ (string, default: null)
  - _purge_protection_enabled_ (bool, default: false)
  - _soft_delete_retention_days_ (number, default: 7)
  - _tags_ (map(string), default: null)

### Recommended
- _app_secrets_ (list(object), default: [])
  - **name** (string, required): Key Vault secret name.
  - _app_setting_ (string, optional): App setting key to bind via Key Vault reference. If omitted, the secret is created but not bound.
  - _initial_value_ (string, optional): Seed value for first deploy. Subsequent changes are ignored. Populate/rotate via Azure Portal or CI.

- _managed_identity_principal_id_ (string, default: null)
  - Principal ID of the managed identity to assign Key Vault permissions to. If you already handle this permission elsewhere, you may omit this value.

## Outputs

- _key_vault_: The Key Vault instance used (regardless of whether it was created by the module or reused).
- _app_settings_bindings_: An object mapping the provided app_settings keys to their corresponding Key Vault reference URIs.