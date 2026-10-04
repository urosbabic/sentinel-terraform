data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "sentinel" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_storage_account" "terraform_state" {
  name                              = var.storage_account_name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_kind                      = "StorageV2"
  account_tier                      = "Standard"
  account_replication_type          = "LRS"
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false
  public_network_access_enabled     = true
  infrastructure_encryption_enabled = true

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    managed-by = "terraform"
    purpose    = "sentinel-terraform-state"
  }
}

resource "azapi_resource" "terraform_state_container" {
  type      = "Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01"
  name      = "tfstate"
  parent_id = "${azurerm_storage_account.terraform_state.id}/blobServices/default"

  body = {
    properties = {
      publicAccess = "None"
    }
  }
}

resource "azurerm_role_assignment" "terraform_state_access" {
  scope                = azapi_resource.terraform_state_container.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.github_actions_service_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "sentinel_access" {
  scope                = data.azurerm_log_analytics_workspace.sentinel.id
  role_definition_name = "Microsoft Sentinel Contributor"
  principal_id         = var.github_actions_service_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "logic_apps_access" {
  count = var.should_grant_logic_apps_contributor ? 1 : 0

  scope                = data.azurerm_resource_group.target.id
  role_definition_name = "Logic Apps Contributor"
  principal_id         = var.github_actions_service_principal_object_id
  principal_type       = "ServicePrincipal"
}
