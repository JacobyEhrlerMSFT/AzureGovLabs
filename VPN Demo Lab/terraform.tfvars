### Must support Zones or change main.tf 
location = "usgovvirginia"

##MUST CHANGE BASE NAME
base_name = "lmco"

###Subnets for Hubvnet need to be within hubvnet address range
address_space_hubvnet = ["10.1.0.0/16"]
address_space_bastionsub = ["10.1.1.0/24"]
address_space_jumpsub = ["10.1.2.0/24"]
address_space_jumpsubext = ["10.1.3.0/24"]
address_space_fwmgmtsub = ["10.1.4.0/24"]
address_space_fwsub = ["10.1.5.0/24"]



### Spoke 1 VNet and Sub
address_space_spoke1vnet = ["10.2.0.0/16"]
address_space_spoke1subnet = ["10.2.0.0/24"]

### Spoke 2 VNet and Sub
address_space_spoke2vnet = ["10.3.0.0/16"]
address_space_spoke2subnet = ["10.3.0.0/24"]
