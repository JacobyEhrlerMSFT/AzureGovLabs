#Project variables

variable "location" {
  type        = string
  description = "The location for the deployment"
  default     = "usgovvirginia"
}

variable "MgmtgrpID" {
  type        = string
  description = "Resource Group Name"
}

variable "SubID" {
  type        = string
  description = "Resource Group Name"
}

variable "msft_application_name_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:application:name"
}

variable "msft_cost_allocation_costcenter_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:cost-allocation:costcenter"
}

variable "msft_cost_allocation_portfolio_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:cost-allocation:portfolio"
}

variable "msft_operations_team_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:operations:team"
}

variable "msft_application_owner_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:application:owner"
}

variable "msft_automation_environment_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:automation:environment"
}

variable "msft_access_control_boundary_allowedValues" {
  type    = list(string)
  default = ["dev", "test", "prod"]
  description = "Allowed values for MSFT:access-control:boundary"
}