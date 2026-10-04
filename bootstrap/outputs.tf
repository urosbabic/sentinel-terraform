output "storage_account_name" {
  description = "Name of the dedicated Terraform state storage account"
  value       = azurerm_storage_account.terraform_state.name
}

output "storage_account_resource_group" {
  description = "Resource group containing the Terraform state storage account"
  value       = azurerm_storage_account.terraform_state.resource_group_name
}

output "state_container_name" {
  description = "Private blob container used for Terraform state"
  value       = azapi_resource.terraform_state_container.name
}

output "sentinel_workspace_resource_id" {
  description = "Resource ID of the Sentinel workspace receiving the deployment role"
  value       = data.azurerm_log_analytics_workspace.sentinel.id
}
