#Project variables

variable "location" {
    type = string
    description = "The location for the deployment"
    default = "usgovvirginia"
}

variable "SubID" {
    type = string
    description = "Resource Group Name"
}

variable "base_name" {
    type = string
    description = "Resource Group Name"
}

variable "address_space" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_subnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}
