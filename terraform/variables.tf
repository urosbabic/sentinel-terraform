variable "resource_group_name" {
  description = "Name of the resource group containing the Sentinel workspace"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics workspace onboarded to Sentinel"
  type        = string
}

variable "enabled_playbooks" {
  description = "Playbook directory names to deploy"
  type        = set(string)
  default     = []
}

variable "playbook_parameters" {
  description = "ARM template parameter values keyed by playbook directory name"
  type        = map(map(any))
  default     = {}
  sensitive   = true
}

variable "playbook_connections" {
  description = "Logic App managed API connections keyed by playbook directory name"
  type        = map(any)
  default     = {}
  sensitive   = true
}
