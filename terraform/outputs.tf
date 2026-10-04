output "analytic_rule_ids" {
  description = "Resource IDs of the managed Sentinel analytic rules"
  value       = { for key, rule in azurerm_sentinel_alert_rule_scheduled.detection : key => rule.id }
}
