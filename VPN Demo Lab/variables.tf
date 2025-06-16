#Project variables

variable "location" {
    type = string
    description = "The location for the deployment"
    default = "usgovvirginia"
}

variable "base_name" {
    type = string
    description = "Resource Group Name"
}


variable "address_space_hubvnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_fwsub" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_fwmgmtsub" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_bastionsub" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_jumpsub" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_jumpsubext" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_spoke1vnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_spoke1subnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_spoke2vnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}

variable "address_space_spoke2subnet" {
    type = list(any)
    description = "VNET Address Space"
    default = ["10.13.0.0/16"]
}