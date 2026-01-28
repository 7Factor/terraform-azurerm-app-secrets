variable "app_secrets" {
  description = "List of secrets to create and optionally create app settings bindings for."
  type = list(object({
    name             = string
    app_setting_name = optional(string)
    initial_value    = optional(string)
  }))
  default   = []
  sensitive = true

  validation {
    condition     = length([for s in var.app_secrets : s.name]) == length(distinct([for s in var.app_secrets : s.name]))
    error_message = "Each app_secrets entry must have a unique 'name'."
  }
}

locals {
  app_secrets_by_name = {
    for s in nonsensitive(var.app_secrets) : s.name => sensitive(s)
  }
  app_secret_bindings = {
    for s in nonsensitive(var.app_secrets) : s.app_setting_name => s.name
    if s.app_setting_name != null && length(s.app_setting_name) > 0
  }
}

variable "key_vault_settings" {
  description = "Key Vault settings. `name` and `rg_name` are required"
  type = object({
    name                       = string
    rg_name                    = string
    externally_created         = optional(bool, false)
    sku                        = optional(string, "standard")
    purge_protection_enabled   = optional(bool, false)
    soft_delete_retention_days = optional(number, 7)
  })
}

variable "managed_identity_principal_id" {
  description = "(Optional) Principal ID of the managed identity to assign Key Vault permissions to. If you already handle this permission elsewhere, you may omit this value."
  type        = string
  default     = null
}