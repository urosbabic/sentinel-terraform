---
title: Sentinel Terraform
description: Manage Microsoft Sentinel scheduled analytic rules with Terraform and GitHub Actions OIDC
---

# Sentinel Terraform

Manage Microsoft Sentinel scheduled analytic rules as code. Detection metadata
lives in YAML files under `detections/`, and each rule's KQL is stored in a
separate query file.

## Repository layout

* `detections/` contains rule metadata and KQL queries.
* `terraform/` contains the AzureRM configuration.
* `.github/workflows/terraform.yml` validates pull requests and deploys changes
  from `main`.

## Prerequisites

* Terraform 1.16.5 or later in the 1.x line.
* An existing Log Analytics workspace onboarded to Microsoft Sentinel.
* An Azure application with a federated credential for the `production`
  GitHub Actions environment.
* A remote state storage account and blob container.
* Sentinel Contributor on the target workspace and Storage Blob Data Contributor
  on the state container for the deployment identity.

## Configure GitHub

Add these repository or `production` environment variables:

| Variable | Purpose |
| --- | --- |
| `AZURE_CLIENT_ID` | Entra application (client) ID used for OIDC |
| `AZURE_TENANT_ID` | Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription containing the workspace and state account |
| `SENTINEL_RESOURCE_GROUP` | Resource group containing the Sentinel workspace |
| `SENTINEL_WORKSPACE_NAME` | Log Analytics workspace name |
| `TF_STATE_RESOURCE_GROUP` | Resource group containing the Terraform state account |
| `TF_STATE_STORAGE_ACCOUNT` | Existing storage account for Terraform state |
| `TF_STATE_CONTAINER` | Existing blob container for Terraform state |
| `ENABLE_SENTINEL_DEPLOYMENT` | Set to `true` after configuring and reviewing the deployment |

Create a federated identity credential with issuer
`https://token.actions.githubusercontent.com`, audience
`api://AzureADTokenExchange`, and subject
`repo:urosbabic/sentinel-terraform:environment:production`.

Restrict the `production` environment to the `main` branch. Add required
reviewers if deployments need manual approval. The workflow grants Azure OIDC
permissions only to that environment, not to pull request jobs.
Deployment runs remain disabled until `ENABLE_SENTINEL_DEPLOYMENT` is set to
`true`.

## Add an analytic rule

Copy `detections/example.yaml` and provide a unique GUID in `name`. Keep
`query_file` relative to the repository root, then add the referenced KQL file
under `detections/queries/`. Set `enabled: true` only after validating the
query against the target workspace.

The workflow validates pull requests without Azure credentials. Pushes to
`main` and manual workflow runs initialize the remote backend, create a plan,
and apply it. Removing a YAML rule from the repository also removes the
corresponding Terraform-managed rule on the next apply. Import existing rules
into Terraform state before managing them to prevent duplicate resources.

## Run locally

Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and
set the target workspace values. Log in with Azure CLI and initialize Terraform
with backend configuration for the existing state storage account:

```powershell
az login
terraform -chdir=terraform init `
  -backend-config="resource_group_name=<state-resource-group>" `
  -backend-config="storage_account_name=<state-storage-account>" `
  -backend-config="container_name=<state-container>" `
  -backend-config="key=sentinel-terraform.tfstate" `
  -backend-config="use_azuread_auth=true"
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

Review the plan before applying it. Do not commit state files, plans, or
`terraform.tfvars`.
