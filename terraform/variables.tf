variable "resource_group_name" {
  description = "Name of the resource group containing the Sentinel workspace"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace onboarded to Sentinel"
  type        = string
}
