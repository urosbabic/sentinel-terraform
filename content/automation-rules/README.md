---
title: Sentinel automation rule manifests
description: Author JSON manifests for Terraform-managed Sentinel automation rules
---

## Authoring automation rules

Add one JSON file per rule under this directory. Each file must contain a
GUID-valued `name` and a `properties` object accepted by the
`Microsoft.SecurityInsights/automationRules` API. Terraform passes the
`properties` object to that API without rewriting its fields.

The source repository had no automation rule definitions to migrate. Review
the Azure API requirements and import any existing rules before applying new
manifests.
