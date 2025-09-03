terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  environment     = "usgovernment"
  subscription_id = var.SubID
}

# Local values for tag configuration
locals {
  required_tags = {
    "MSFT:application:name"           = "name"
    "MSFT:cost-allocation:costcenter" = "costcenter"
    "MSFT:cost-allocation:portfolio"  = "portfolio"
    "MSFT:operations:team"            = "team"
    "MSFT:application:owner"          = "owner"
    "MSFT:automation:environment"     = "environment"
    "MSFT:access-control:boundary"    = "boundary"
  }

  # Policy definition IDs
  require_tag_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
  inherit_tag_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
}

################### Policy Set Definition (Initiative) ############################################## 

# Create policy set definition for MSFT tag requirements
resource "azurerm_policy_set_definition" "ngc_tags_initiative" {
  name                = "msft-tags-initiative"
  policy_type         = "Custom"
  display_name        = "MSFT Tag Governance Initiative"
  description         = "Policy initiative to enforce and inherit MSFT organizational tags on resource groups and resources"
  management_group_id = var.MgmtgrpID

  # Require tag policies
  dynamic "policy_definition_reference" {
    for_each = local.required_tags
    content {
      policy_definition_id = local.require_tag_policy_id
      reference_id         = "require-${policy_definition_reference.value}"
      parameter_values = jsonencode({
        tagName = {
          value = policy_definition_reference.key
        }
      })
    }
  }

  # Inherit tag policies
  dynamic "policy_definition_reference" {
    for_each = local.required_tags
    content {
      policy_definition_id = local.inherit_tag_policy_id
      reference_id         = "inherit-${policy_definition_reference.value}"
      parameter_values = jsonencode({
        tagName = {
          value = policy_definition_reference.key
        }
      })
    }
  }
}

