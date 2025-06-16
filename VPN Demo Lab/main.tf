terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

provider "azurerm" {
  alias           = "virginia"
  features        {}
  environment     = "usgovernment"
  subscription_id = "23752682-ecfe-481d-98a4-f6d457f67322"
}

provider "azurerm" {
  alias           = "arizona"
  features        {}
  environment     = "usgovernment"
  subscription_id = "23752682-ecfe-481d-98a4-f6d457f67322"
}

locals {
  tags = {
    "LAB:application:Name"         = "LandingZone"
    "LAB:operations:TechnicalPOC"  = "jaehrler"
    "LAB:automation:Environment"   = "Terraform"
  }
}

# Virginia Landing Zone
resource "azurerm_resource_group" "va" {
  provider = azurerm.virginia
  name     = "rg-lzva"
  location = "usgovvirginia"
  tags     = local.tags
}

resource "azurerm_virtual_network" "va_hub" {
  provider            = azurerm.virginia
  name                = "vnet-lzva-hub"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  tags                = local.tags
}

resource "azurerm_subnet" "va_gw" {
  provider                  = azurerm.virginia
  name                      = "GatewaySubnet"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_hub.name
  address_prefixes          = ["10.10.0.0/24"]
}

resource "azurerm_subnet" "va_fw" {
  provider                  = azurerm.virginia
  name                      = "AzureFirewallSubnet"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_hub.name
  address_prefixes          = ["10.10.1.0/24"]
}

resource "azurerm_virtual_network" "va_spoke" {
  provider            = azurerm.virginia
  name                = "vnet-lzva-spoke"
  address_space       = ["10.11.0.0/16"]
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  tags                = local.tags
}

resource "azurerm_subnet" "va_spoke_subnet" {
  provider                  = azurerm.virginia
  name                      = "default"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_spoke.name
  address_prefixes          = ["10.11.1.0/24"]
}

resource "azurerm_public_ip" "va_fw" {
  provider            = azurerm.virginia
  name                = "pip-lzva-fw"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "va" {
  provider            = azurerm.virginia
  name                = "fw-lzva"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.va_fw.id
    public_ip_address_id = azurerm_public_ip.va_fw.id
  }
  tags = local.tags
}

# Virginia Firewall Rules - Allow All Traffic
resource "azurerm_firewall_network_rule_collection" "va_allow_all" {
  provider            = azurerm.virginia
  name                = "AllowAllNetwork"
  azure_firewall_name = azurerm_firewall.va.name
  resource_group_name = azurerm_resource_group.va.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "AllowAll"
    protocols             = ["Any"]
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
  }
}


resource "azurerm_public_ip" "va_gw" {
  provider            = azurerm.virginia
  name                = "pip-lzva-gw"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "va" {
  provider            = azurerm.virginia
  name                = "vng-lzva"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"
  ip_configuration {
    name                          = "vng-ipconfig"
    public_ip_address_id          = azurerm_public_ip.va_gw.id
    subnet_id                     = azurerm_subnet.va_gw.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.tags
}

resource "azurerm_network_interface" "va_vm" {
  provider            = azurerm.virginia
  name                = "nic-lzva-vm"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.va_spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "va" {
  provider            = azurerm.virginia
  name                = "vm-lzva"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.va_vm.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Arizona Landing Zone
resource "azurerm_resource_group" "az" {
  provider = azurerm.arizona
  name     = "rg-lzaz"
  location = "usgovarizona"
  tags     = local.tags
}

resource "azurerm_virtual_network" "az_hub" {
  provider            = azurerm.arizona
  name                = "vnet-lzaz-hub"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  tags                = local.tags
}

resource "azurerm_subnet" "az_gw" {
  provider                  = azurerm.arizona
  name                      = "GatewaySubnet"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_hub.name
  address_prefixes          = ["10.20.0.0/24"]
}

resource "azurerm_subnet" "az_fw" {
  provider                  = azurerm.arizona
  name                      = "AzureFirewallSubnet"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_hub.name
  address_prefixes          = ["10.20.1.0/24"]
}

resource "azurerm_virtual_network" "az_spoke" {
  provider            = azurerm.arizona
  name                = "vnet-lzaz-spoke"
  address_space       = ["10.21.0.0/16"]
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  tags                = local.tags
}

resource "azurerm_subnet" "az_spoke_subnet" {
  provider                  = azurerm.arizona
  name                      = "default"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_spoke.name
  address_prefixes          = ["10.21.1.0/24"]
}

resource "azurerm_public_ip" "az_fw" {
  provider            = azurerm.arizona
  name                = "pip-lzaz-fw"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "az" {
  provider            = azurerm.arizona
  name                = "fw-lzaz"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.az_fw.id
    public_ip_address_id = azurerm_public_ip.az_fw.id
  }
  tags = local.tags
}

# Arizona Firewall Rules - Allow All Traffic
resource "azurerm_firewall_network_rule_collection" "az_allow_all" {
  provider            = azurerm.arizona
  name                = "AllowAllNetwork"
  azure_firewall_name = azurerm_firewall.az.name
  resource_group_name = azurerm_resource_group.az.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "AllowAll"
    protocols             = ["Any"]
    source_addresses      = ["*"]
    destination_addresses = ["*"]
    destination_ports     = ["*"]
  }
}

resource "azurerm_public_ip" "az_gw" {
  provider            = azurerm.arizona
  name                = "pip-lzaz-gw"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "az" {
  provider            = azurerm.arizona
  name                = "vng-lzaz"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"
  ip_configuration {
    name                          = "vng-ipconfig"
    public_ip_address_id          = azurerm_public_ip.az_gw.id
    subnet_id                     = azurerm_subnet.az_gw.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = local.tags
}

resource "azurerm_network_interface" "az_vm" {
  provider            = azurerm.arizona
  name                = "nic-lzaz-vm"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.az_spoke_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "az" {
  provider            = azurerm.arizona
  name                = "vm-lzaz"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = "P@ssword1234!"
  network_interface_ids = [
    azurerm_network_interface.az_vm.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

# Log Analytics Workspace (shared for both firewalls)
resource "azurerm_log_analytics_workspace" "main" {
  provider = azurerm.virginia
  name                = "law-lz-firewall"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# Virginia Firewall Diagnostic Setting
resource "azurerm_monitor_diagnostic_setting" "va_fw" {
  provider = azurerm.virginia
  name                       = "fw-logs"
  target_resource_id         = azurerm_firewall.va.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
}

# Arizona Firewall Diagnostic Setting
resource "azurerm_monitor_diagnostic_setting" "az_fw" {
  provider = azurerm.arizona
  name                       = "fw-logs"
  target_resource_id         = azurerm_firewall.az.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category_group = "allLogs"
  }
}

# Virginia Local Network Gateway (represents Arizona VPN Gateway)
resource "azurerm_local_network_gateway" "va_to_az" {
  provider            = azurerm.virginia
  name                = "lngw-va-to-az"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  gateway_address     = azurerm_public_ip.az_gw.ip_address
  address_space       = [
    "10.20.0.0/16", # Arizona Hub
    "10.21.0.0/16"  # Arizona Spoke
  ]
  tags                = local.tags
}

# Arizona Local Network Gateway (represents Virginia VPN Gateway)
resource "azurerm_local_network_gateway" "az_to_va" {
  provider            = azurerm.arizona
  name                = "lngw-az-to-va"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  gateway_address     = azurerm_public_ip.va_gw.ip_address
  address_space       = [
    "10.10.0.0/16", # Virginia Hub
    "10.11.0.0/16"  # Virginia Spoke
  ]
  tags                = local.tags
}

# S2S VPN Connections
resource "azurerm_virtual_network_gateway_connection" "va_to_az" {
  provider                        = azurerm.virginia
  name                            = "va-to-az-conn"
  location                        = azurerm_resource_group.va.location
  resource_group_name             = azurerm_resource_group.va.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.va.id
  local_network_gateway_id        = azurerm_local_network_gateway.va_to_az.id

  shared_key                      = "SuperSecretSharedKey123!"
}

resource "azurerm_virtual_network_gateway_connection" "az_to_va" {
  provider                        = azurerm.arizona
  name                            = "az-to-va-conn"
  location                        = azurerm_resource_group.az.location
  resource_group_name             = azurerm_resource_group.az.name

  type                            = "IPsec"
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.az.id
  local_network_gateway_id        = azurerm_local_network_gateway.az_to_va.id

  shared_key                      = "SuperSecretSharedKey123!"
}

resource "azurerm_virtual_network_peering" "va_hub_to_spoke" {
  provider                  = azurerm.virginia
  name                      = "va-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_hub.name
  remote_virtual_network_id = azurerm_virtual_network.va_spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Virginia VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "va_spoke_to_hub" {
  provider                  = azurerm.virginia
  name                      = "va-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.va_hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

# Arizona VNet Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "az_hub_to_spoke" {
  provider                  = azurerm.arizona
  name                      = "az-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_hub.name
  remote_virtual_network_id = azurerm_virtual_network.az_spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

# Arizona VNet Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "az_spoke_to_hub" {
  provider                  = azurerm.arizona
  name                      = "az-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_spoke.name
  remote_virtual_network_id = azurerm_virtual_network.az_hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

# Virginia Route Table for Hub
resource "azurerm_route_table" "va_hub" {
  provider            = azurerm.virginia
  name                = "rt-lzva-hub"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  tags                = local.tags
}

resource "azurerm_route" "va_hub_default" {
  provider               = azurerm.virginia
  name                   = "default-to-fw"
  resource_group_name    = azurerm_resource_group.va.name
  route_table_name       = azurerm_route_table.va_hub.name
  address_prefix         = "10.11.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.va.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "va_hub_gw" {
  provider       = azurerm.virginia
  subnet_id      = azurerm_subnet.va_gw.id
  route_table_id = azurerm_route_table.va_hub.id
}

# Virginia Route Table for Spoke
resource "azurerm_route_table" "va_spoke" {
  provider            = azurerm.virginia
  name                = "rt-lzva-spoke"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  tags                = local.tags
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "va_spoke_default" {
  provider               = azurerm.virginia
  name                   = "default-to-fw"
  resource_group_name    = azurerm_resource_group.va.name
  route_table_name       = azurerm_route_table.va_spoke.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.va.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "va_spoke" {
  provider       = azurerm.virginia
  subnet_id      = azurerm_subnet.va_spoke_subnet.id
  route_table_id = azurerm_route_table.va_spoke.id
}

# Arizona Route Table for Hub
resource "azurerm_route_table" "az_hub" {
  provider            = azurerm.arizona
  name                = "rt-lzaz-hub"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  tags                = local.tags
}

resource "azurerm_route" "az_hub_default" {
  provider               = azurerm.arizona
  name                   = "default-to-fw"
  resource_group_name    = azurerm_resource_group.az.name
  route_table_name       = azurerm_route_table.az_hub.name
  address_prefix         = "10.21.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.az.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "az_hub_gw" {
  provider       = azurerm.arizona
  subnet_id      = azurerm_subnet.az_gw.id
  route_table_id = azurerm_route_table.az_hub.id
}

# Arizona Route Table for Spoke
resource "azurerm_route_table" "az_spoke" {
  provider            = azurerm.arizona
  name                = "rt-lzaz-spoke"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  tags                = local.tags
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "az_spoke_default" {
  provider               = azurerm.arizona
  name                   = "default-to-fw"
  resource_group_name    = azurerm_resource_group.az.name
  route_table_name       = azurerm_route_table.az_spoke.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.az.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "az_spoke" {
  provider       = azurerm.arizona
  subnet_id      = azurerm_subnet.az_spoke_subnet.id
  route_table_id = azurerm_route_table.az_spoke.id
}

# Virginia Bastion Subnet
resource "azurerm_subnet" "va_bastion" {
  provider                  = azurerm.virginia
  name                      = "AzureBastionSubnet"
  resource_group_name       = azurerm_resource_group.va.name
  virtual_network_name      = azurerm_virtual_network.va_hub.name
  address_prefixes          = ["10.10.2.0/27"]
}

resource "azurerm_public_ip" "va_bastion" {
  provider            = azurerm.virginia
  name                = "pip-lzva-bastion"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "va" {
  provider            = azurerm.virginia
  name                = "bastion-lzva"
  location            = azurerm_resource_group.va.location
  resource_group_name = azurerm_resource_group.va.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.va_bastion.id
    public_ip_address_id = azurerm_public_ip.va_bastion.id
  }
  tags = local.tags
}

# Arizona Bastion Subnet
resource "azurerm_subnet" "az_bastion" {
  provider                  = azurerm.arizona
  name                      = "AzureBastionSubnet"
  resource_group_name       = azurerm_resource_group.az.name
  virtual_network_name      = azurerm_virtual_network.az_hub.name
  address_prefixes          = ["10.20.2.0/27"]
}

resource "azurerm_public_ip" "az_bastion" {
  provider            = azurerm.arizona
  name                = "pip-lzaz-bastion"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "az" {
  provider            = azurerm.arizona
  name                = "bastion-lzaz"
  location            = azurerm_resource_group.az.location
  resource_group_name = azurerm_resource_group.az.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.az_bastion.id
    public_ip_address_id = azurerm_public_ip.az_bastion.id
  }
  tags = local.tags
}