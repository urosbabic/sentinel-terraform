locals {
  detection_files = fileset("${path.module}/../detections", "**/*.yaml")
  detections = {
    for detection_file in local.detection_files :
    trimsuffix(detection_file, ".yaml") => yamldecode(file("${path.module}/../detections/${detection_file}"))
  }
}

data "azurerm_log_analytics_workspace" "target" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_sentinel_alert_rule_scheduled" "detection" {
  for_each = local.detections

  name                       = each.value.name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.target.workspace_id
  display_name               = each.value.display_name
  description                = each.value.description
  severity                   = each.value.severity
  query                      = file("${path.module}/../${each.value.query_file}")
  query_frequency            = each.value.query_frequency
  query_period               = each.value.query_period
  trigger_operator           = each.value.trigger_operator
  trigger_threshold          = each.value.trigger_threshold
  enabled                    = each.value.enabled
  tactics                    = try(each.value.tactics, [])
}
