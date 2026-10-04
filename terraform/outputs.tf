output "analytic_rule_ids" {
  description = "Resource IDs of the managed Sentinel analytic rules"
  value       = { for key, rule in azapi_resource.analytics_rule : key => rule.id }
}

output "automation_rule_ids" {
  description = "Resource IDs of the managed Sentinel automation rules"
  value       = { for key, rule in azapi_resource.automation_rule : key => rule.id }
}

output "hunting_query_ids" {
  description = "Resource IDs of the managed hunting queries"
  value       = { for key, query in azapi_resource.hunting_query : key => query.id }
}

output "parser_ids" {
  description = "Resource IDs of the managed workspace parsers"
  value       = { for key, parser in azapi_resource.parser : key => parser.id }
}

output "playbook_deployment_ids" {
  description = "Resource IDs of the ARM deployments used for Logic App playbooks"
  value       = { for key, playbook in azapi_resource.playbook_template : key => playbook.id }
}

output "playbook_workflow_ids" {
  description = "Resource IDs of the managed Logic App workflows"
  value       = { for key, playbook in azapi_resource.playbook_workflow : key => playbook.id }
}

output "workbook_ids" {
  description = "Resource IDs of the managed Sentinel workbooks"
  value       = { for key, workbook in azapi_resource.workbook : key => workbook.id }
}
