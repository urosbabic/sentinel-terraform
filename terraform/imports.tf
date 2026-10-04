// These IDs were confirmed in Sentinel-LAW; remove this file after the initial import is applied.
locals {
  existing_analytics_rule_ids = toset([
    "f277ffe7-7e87-4a52-ab31-25fbd8b50d01",
    "978adfdd-c5e6-4f27-87b2-259e23d8447c",
    "123778f9-1be4-4bb8-adcc-c47b9a0d8184",
    "f91b60e3-2e1e-4d73-beec-30a0b774c281",
    "6abe19d7-09c0-4039-807a-86d789da5c9c",
    "2dedd20f-2951-41b8-9727-1baf4c26a4a7",
    "58deb816-0939-417f-95f2-05a9dc5d0b2c",
    "d14ed162-636a-487c-9f69-ed049cb82577",
    "d9c33d2a-b6c6-4dd6-9467-670ce2a2d62c",
    "ccaf13de-c43a-4e6b-a317-7d0b18543477",
    "b59d576c-a6c1-47d4-8685-f81bfcf155e9",
    "2e99f0c6-8b52-46a0-9ea4-eb84d11a2b2a",
    "7bfdf8f9-237e-4c44-be98-ea3d751edcd2",
    "637fd019-d563-4292-92dd-3c4194e04ea8",
    "2a9f2173-94f8-4b0c-b085-a53fb512da28",
    "033c9213-ebef-426d-b228-feafe932cae0",
    "c2730362-f8e7-4369-85db-8ac7af65ee01",
    "e5a356c4-0f8b-4d23-a356-0caf80a0fbf5",
    "f8c12791-4bf3-4134-8365-91abec544122",
    "8a653912-657e-409e-a911-19e1d110baa1",
    "33609de4-5fa4-42ff-bec8-8b6713c30298",
    "d45ad7f1-5db6-4a65-89b4-7141f0b45619",
    "35c94c09-afd3-4141-b5f6-4cbb67e00998",
    "c819e1b6-29b4-4693-a6ab-66038bcaeef9",
    "db0a3672-033b-48f0-9531-c3eb75c69d50",
    "110fcb93-6520-41a7-a17e-eb45e3ada76d",
    "3ed871a1-45f6-4584-8b72-de1f125c22c8",
    "82007097-3881-43db-9801-ff8611c1e8c1",
    "3ec71b57-7b5b-430d-9db1-208a134553f0",
    "93f64b3b-ac44-40fe-815e-6f05fb72dad8",
    "2ca843a1-0dd7-41f9-a1ae-ca739c941d74",
    "4ce03f95-e37e-497e-968e-9cc79554b2de",
    "562d91da-1cef-4cb6-9fdb-eacc1963ad9c",
    "2134c14b-84b0-4329-8532-195d7930f91b",
    "25eb5776-437b-4772-9895-42f03ec776b5",
    "b75f46db-21e9-4ee4-8460-6a6aea41db53",
    "4802f51c-fda5-4eb1-a8bb-5a2ca194bb19",
    "8c3ce005-aa8d-4970-9fa5-56e6cd911b8e",
    "3ff61aae-69ca-4fa4-8891-32464d5e3dde",
    "15121201-c387-47e1-866c-fe1f711d4a7e",
    "00fca433-505e-46c8-8ef7-eaf3d6f7f790",
    "7d269b05-9400-468f-b2a0-20dd6a79e41d",
    "d7858e9b-38b6-4b2c-89a7-0718a370849a",
    "b47c429c-2ee2-4411-ab27-bee65587b3a8",
    "d3997945-0ac4-4917-afa1-b40c4a4f9f5c",
    "aed11b0b-c1a0-4ea5-9d33-2e02f06f5bdc",
    "120d393a-5a36-4e98-84d6-53e4178c1e09",
    "858903d9-0a3f-4ea1-b2b9-03ae139ad484",
    "9d1c9b03-f953-42f3-8308-a95179392df5",
    "7090645f-c96d-4edc-98bd-0dd1d0cbfa6a",
  ])

  existing_analytics_rules = {
    for file_name, rule in local.analytics_rules :
    file_name => rule.id
    if contains(local.existing_analytics_rule_ids, lower(rule.id))
  }
}

import {
  for_each = local.existing_analytics_rules
  to       = azapi_resource.analytics_rule[each.key]
  id       = "${data.azurerm_log_analytics_workspace.target.id}/providers/Microsoft.SecurityInsights/alertRules/${each.value}"
}
