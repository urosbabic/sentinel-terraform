locals {
  analytics_rule_files = fileset("${path.module}/../content/analytics-rules", "**/*.yaml")
  analytics_rules = {
    for rule_file in local.analytics_rule_files :
    rule_file => yamldecode(file("${path.module}/../content/analytics-rules/${rule_file}"))
  }
  analytics_rule_optional_properties = [
    "entityMappings",
    "incidentConfiguration",
    "eventGroupingSettings",
    "suppressionDuration",
    "suppressionEnabled",
    "customDetails",
    "alertRuleTemplateName",
  ]
  trigger_operators = {
    gt = "GreaterThan"
    lt = "LessThan"
    eq = "Equal"
  }
  analytics_rule_properties = {
    for rule_file, rule in local.analytics_rules :
    rule_file => merge(
      {
        displayName = rule.name
        description = rule.description
        severity    = rule.severity
        enabled     = try(rule.status, "Available") != "Disabled"
        query       = rule.query
        suppressionDuration = coalesce(
          try(rule.suppressionDuration, null),
          "PT5H",
        )
        suppressionEnabled = coalesce(
          try(rule.suppressionEnabled, null),
          false,
        )
        tactics    = try(rule.tactics, [])
        techniques = coalesce(try(rule.techniques, null), try(rule.relevantTechniques, null), [])
      },
      try(rule.kind, "Scheduled") == "Scheduled" ? {
        queryFrequency  = rule.queryFrequency
        queryPeriod     = rule.queryPeriod
        triggerOperator = lookup(local.trigger_operators, lower(rule.triggerOperator), rule.triggerOperator)
      } : {},
      try(rule.kind, "Scheduled") == "Scheduled" ? {
        triggerThreshold = tonumber(rule.triggerThreshold)
      } : {},
      {
        for property_name in local.analytics_rule_optional_properties :
        property_name => rule[property_name]
        if try(rule[property_name], null) != null
      },
      try(rule.alertDetailsOverride, null) != null ? {
        alertDetailsOverride = {
          for override_name, override_value in rule.alertDetailsOverride :
          (lower(override_name) == "alertnameformat" ? "alertDisplayNameFormat" : override_name) => override_value
        }
      } : {},
    )
  }

  hunting_query_files = fileset("${path.module}/../content/hunting-queries", "**/*.kql")
  hunting_queries = {
    for query_file in local.hunting_query_files :
    query_file => {
      display_name = trimsuffix(basename(query_file), ".kql")
      query        = file("${path.module}/../content/hunting-queries/${query_file}")
      resource_name = "${substr(
        replace(lower(query_file), "/[^a-z0-9-]/", "-"),
        0,
        48,
      )}-${substr(sha1(query_file), 0, 8)}"
    }
  }

  parser_files = fileset("${path.module}/../content/parsers", "**/*.kql")
  parsers = {
    for parser_file in local.parser_files :
    parser_file => {
      display_name   = trimsuffix(basename(parser_file), ".kql")
      function_alias = replace(trimsuffix(basename(parser_file), ".kql"), "/[^A-Za-z0-9_]/", "_")
      query          = file("${path.module}/../content/parsers/${parser_file}")
      resource_name = "${substr(
        replace(lower(parser_file), "/[^a-z0-9-]/", "-"),
        0,
        48,
      )}-${substr(sha1(parser_file), 0, 8)}"
    }
  }

  automation_rule_files = fileset("${path.module}/../content/automation-rules", "**/*.json")
  automation_rules = {
    for rule_file in local.automation_rule_files :
    rule_file => jsondecode(file("${path.module}/../content/automation-rules/${rule_file}"))
  }

  workbook_files = fileset("${path.module}/../content/workbooks", "**/*.json")
  workbooks = {
    for workbook_file in local.workbook_files :
    workbook_file => jsondecode(file("${path.module}/../content/workbooks/${workbook_file}"))
  }

  playbook_template_files = fileset("${path.module}/../content/playbooks", "**/azuredeploy.json")
  playbook_templates = {
    for template_file in local.playbook_template_files :
    dirname(template_file) => {
      template = jsondecode(file("${path.module}/../content/playbooks/${template_file}"))
    }
  }

  playbook_workflow_files = fileset("${path.module}/../content/playbooks", "**/workflow-definition.json")
  playbook_workflows = {
    for workflow_file in local.playbook_workflow_files :
    dirname(workflow_file) => jsondecode(file("${path.module}/../content/playbooks/${workflow_file}"))
  }
  available_playbooks = distinct(concat(
    keys(local.playbook_templates),
    keys(local.playbook_workflows),
  ))
  enabled_playbook_templates = {
    for name, playbook in local.playbook_templates :
    name => playbook
    if contains(var.enabled_playbooks, name)
  }
  enabled_playbook_workflows = {
    for name, workflow in local.playbook_workflows :
    name => workflow
    if contains(var.enabled_playbooks, name)
  }
}

data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

data "azurerm_log_analytics_workspace" "target" {
  name                = var.workspace_name
  resource_group_name = var.resource_group_name
}

resource "azapi_resource" "analytics_rule" {
  for_each = local.analytics_rules

  type      = "Microsoft.SecurityInsights/alertRules@2023-02-01-preview"
  name      = each.value.id
  parent_id = data.azurerm_log_analytics_workspace.target.id

  body = {
    kind       = try(each.value.kind, "Scheduled")
    properties = local.analytics_rule_properties[each.key]
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", each.value.id))
      error_message = "Each analytic rule id must be a GUID."
    }

    precondition {
      condition     = contains(["Scheduled", "NRT"], try(each.value.kind, "Scheduled"))
      error_message = "Only Scheduled and NRT analytic rules are supported."
    }
  }
}

resource "azapi_resource" "hunting_query" {
  for_each = local.hunting_queries

  type      = "Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01"
  name      = each.value.resource_name
  parent_id = data.azurerm_log_analytics_workspace.target.id

  body = {
    properties = {
      category    = "Hunting Queries"
      displayName = each.value.display_name
      query       = each.value.query
      version     = 1
    }
  }
}

resource "azapi_resource" "parser" {
  for_each = local.parsers

  type      = "Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01"
  name      = each.value.resource_name
  parent_id = data.azurerm_log_analytics_workspace.target.id

  body = {
    properties = {
      category           = "Parsers"
      displayName        = each.value.display_name
      functionAlias      = each.value.function_alias
      functionParameters = ""
      query              = each.value.query
      version            = 1
    }
  }
}

resource "azapi_resource" "automation_rule" {
  for_each = local.automation_rules

  type      = "Microsoft.SecurityInsights/automationRules@2023-02-01-preview"
  name      = each.value.name
  parent_id = data.azurerm_log_analytics_workspace.target.id

  body = {
    properties = each.value.properties
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", each.value.name))
      error_message = "Each automation rule name must be a GUID."
    }
  }
}

resource "azapi_resource" "workbook" {
  for_each = local.workbooks

  type      = "Microsoft.Insights/workbooks@2022-04-01"
  name      = uuidv5("url", each.key)
  parent_id = data.azurerm_resource_group.target.id
  location  = data.azurerm_log_analytics_workspace.target.location

  body = {
    kind = "shared"
    properties = {
      category    = "sentinel"
      displayName = trimsuffix(basename(each.key), ".json")
      serializedData = replace(
        replace(
          replace(
            jsonencode(merge(each.value, {
              fallbackResourceIds = [data.azurerm_log_analytics_workspace.target.id]
            })),
            "/subscriptions/cec13d05-98c9-4b42-9bb4-194c42c5c186/resourceGroups/chs-uks-siem-rg/providers/Microsoft.OperationalInsights/workspaces/chs-uks-siem-ws",
            data.azurerm_log_analytics_workspace.target.id,
          ),
          "/subscriptions/cec13d05-98c9-4b42-9bb4-194c42c5c186/resourcegroups/chs-uks-siem-rg/providers/microsoft.operationalinsights/workspaces/chs-uks-siem-ws",
          lower(data.azurerm_log_analytics_workspace.target.id),
        ),
        "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}",
        data.azurerm_log_analytics_workspace.target.id,
      )
      sourceId = data.azurerm_log_analytics_workspace.target.id
      version  = "1.0"
    }
  }
}

resource "terraform_data" "playbook_selection" {
  input = sort(tolist(var.enabled_playbooks))

  lifecycle {
    precondition {
      condition     = alltrue([for name in var.enabled_playbooks : contains(local.available_playbooks, name)])
      error_message = "Each enabled_playbooks entry must match a directory under content/playbooks."
    }
  }
}

resource "azapi_resource" "playbook_template" {
  for_each = local.enabled_playbook_templates

  type      = "Microsoft.Resources/deployments@2022-09-01"
  name      = "sentinel-playbook-${substr(sha1(each.key), 0, 10)}"
  parent_id = data.azurerm_resource_group.target.id

  body = {
    properties = {
      mode     = "Incremental"
      template = each.value.template
      parameters = {
        for parameter_name, parameter_value in try(var.playbook_parameters[each.key], {}) :
        parameter_name => { value = parameter_value }
      }
    }
  }

  depends_on = [terraform_data.playbook_selection]

  lifecycle {
    precondition {
      condition = alltrue([
        for parameter_name, parameter_definition in try(each.value.template.parameters, {}) :
        contains(keys(try(var.playbook_parameters[each.key], {})), parameter_name) ||
        contains(keys(parameter_definition), "defaultValue")
      ])
      error_message = "Provide values for every required ARM template parameter before enabling this playbook."
    }
  }
}

resource "azapi_resource" "playbook_workflow" {
  for_each = local.enabled_playbook_workflows

  type      = "Microsoft.Logic/workflows@2019-05-01"
  name      = each.key
  parent_id = data.azurerm_resource_group.target.id
  location  = data.azurerm_log_analytics_workspace.target.location

  body = {
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      state      = "Enabled"
      definition = each.value.definition
      parameters = merge(
        try(each.value.parameters, {}),
        {
          "$connections" = {
            value = try(var.playbook_connections[each.key], {})
          }
        },
      )
    }
  }

  depends_on = [terraform_data.playbook_selection]

  lifecycle {
    precondition {
      condition     = length(try(var.playbook_connections[each.key], {})) > 0
      error_message = "Configure managed API connection references before enabling this Logic App playbook."
    }
  }
}
