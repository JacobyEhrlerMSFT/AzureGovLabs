resource "azurerm_policy_definition" "allowed_tag_values" {
  name         = "allowed-tag-values-per-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed tag values per tag"
  description  = "Restrict tag values to predefined list per tag."

  policy_rule = <<POLICY
{
  "if": {
    "anyOf": [
      {
        "allOf": [
          { "field": "tags['MSFT:application:name']", "exists": true },
          { "field": "tags['MSFT:application:name']", "notIn": "[parameters('msft_application_name_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:cost-allocation:costcenter']", "exists": true },
          { "field": "tags['MSFT:cost-allocation:costcenter']", "notIn": "[parameters('msft_cost_allocation_costcenter_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:cost-allocation:portfolio']", "exists": true },
          { "field": "tags['MSFT:cost-allocation:portfolio']", "notIn": "[parameters('msft_cost_allocation_portfolio_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:operations:team']", "exists": true },
          { "field": "tags['MSFT:operations:team']", "notIn": "[parameters('msft_operations_team_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:application:owner']", "exists": true },
          { "field": "tags['MSFT:application:owner']", "notIn": "[parameters('msft_application_owner_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:automation:environment']", "exists": true },
          { "field": "tags['MSFT:automation:environment']", "notIn": "[parameters('msft_automation_environment_allowedValues')]" }
        ]
      },
      {
        "allOf": [
          { "field": "tags['MSFT:access-control:boundary']", "exists": true },
          { "field": "tags['MSFT:access-control:boundary']", "notIn": "[parameters('msft_access_control_boundary_allowedValues')]" }
        ]
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
POLICY

  parameters = jsonencode({
    msft_application_name_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:application:name"
        description = "Allowed application names"
      }
      defaultValue = var.msft_application_name_allowedValues
    }

    msft_cost_allocation_costcenter_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:cost-allocation:costcenter"
        description = "Allowed cost center codes"
      }
      defaultValue = var.msft_cost_allocation_costcenter_allowedValues
    }

    msft_cost_allocation_portfolio_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:cost-allocation:portfolio"
        description = "Allowed portfolio values"
      }
      defaultValue = var.msft_cost_allocation_portfolio_allowedValues
    }

    msft_operations_team_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:operations:team"
        description = "Allowed operations teams"
      }
      defaultValue = var.msft_operations_team_allowedValues
    }

    msft_application_owner_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:application:owner"
        description = "Allowed application owners"
      }
      defaultValue = var.msft_application_owner_allowedValues
    }

    msft_automation_environment_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:automation:environment"
        description = "Allowed environment values"
      }
      defaultValue = var.msft_automation_environment_allowedValues
    }

    msft_access_control_boundary_allowedValues = {
      type = "Array"
      metadata = {
        displayName = "Allowed values for MSFT:access-control:boundary"
        description = "Allowed access boundary values"
      }
      defaultValue = var.msft_access_control_boundary_allowedValues
    }

    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the policy."
      }
      allowedValues = ["Deny", "Audit", "Disabled"]
      defaultValue = "Deny"
    }
  })
}