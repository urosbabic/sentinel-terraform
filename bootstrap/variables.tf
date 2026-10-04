variable "resource_group_name" {
  description = "Existing resource group for Sentinel and Terraform state"
  type        = string
  default     = "Sentinel-RG"
}

variable "workspace_name" {
  description = "Existing Log Analytics workspace onboarded to Sentinel"
  type        = string
  default     = "Sentinel-LAW"
}

variable "storage_account_name" {
  description = "Globally unique name for the dedicated Terraform state storage account"
  type        = string
  default     = "stsentineltfstateuros01"
}

variable "location" {
  description = "Azure region for the Terraform state storage account"
  type        = string
  default     = "francecentral"
}

variable "github_actions_service_principal_object_id" {
  description = "Object ID of the GitHub Actions service principal"
  type        = string
}

variable "should_grant_logic_apps_contributor" {
  description = "Whether to grant Logic Apps Contributor on the target resource group for playbook deployment"
  type        = bool
  default     = false
}
