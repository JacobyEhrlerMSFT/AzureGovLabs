terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  environment = "usgovernment"
  subscription_id = var.SubID
}


locals {
  tags = {
    "MSFT:application:name" = "AVDPOC"
    "MSFT:cost-allocation:costcenter" = "costcenter"
    "MSFT:cost-allocation:portfolio" = "portfolio"
    "MSFT:operations:team" = "Azure"
    "MSFT:application:owner" = "jaehrler"
    "MSFT:automation:environment" = "Terraform"
    "MSFT:access-control:boundary" = "boundary"
  }
}

resource "azurerm_resource_group" "avd_poc" {
  name     = "AVDPOC"
  tags     = local.tags
  location = var.location
}

resource "azurerm_virtual_network" "avd_vnet" {
  name                = "avd-vnet"
  address_space       = ["10.87.166.224/28", "10.87.166.240/28"]
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags
}

resource "azurerm_subnet" "avd_pe_subnet" {
  name                 = "avd-pe-subnet"
  resource_group_name  = azurerm_resource_group.avd_poc.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.87.166.224/28"]
}

resource "azurerm_subnet" "avd_vm_subnet" {
  name                 = "avd-vm-subnet"
  resource_group_name  = azurerm_resource_group.avd_poc.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = ["10.87.166.240/28"]
}

resource "azurerm_route_table" "avd_rt" {
  name                = "avd-rt"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags

  route {
    name                   = "To-AZ-FW"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.87.64.4"
  }
}

resource "azurerm_virtual_desktop_host_pool" "example" {
  name                = "AVDPOC-EXAMPLE"
  location            = "usgovvirginia"
  resource_group_name = azurerm_resource_group.avd_poc.name
  type                = "Pooled"
  custom_rdp_properties = "drivestoredirect:s:*;usbdevicestoredirect:s:*;redirectclipboard:i:1;redirectprinters:i:1;audiomode:i:0;videoplaybackmode:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;"
  load_balancer_type  = "DepthFirst"
  public_network_access = "Disabled"
  tags = local.tags
}

resource "azurerm_virtual_desktop_application_group" "dag" {
  name                = "AVDPOC-EXAMPLE-DAG"
  location            = "usgovvirginia"
  resource_group_name = azurerm_resource_group.avd_poc.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.example.id
  type                = "Desktop"
  tags                = azurerm_virtual_desktop_host_pool.example.tags
  friendly_name       = "Default Desktop"
  description         = "Desktop Application Group created through the Hostpool Wizard"
}

resource "azurerm_virtual_desktop_application_group" "remoteapp" {
  name                = "EXAMPLE-APP"
  location            = "usgovvirginia"
  resource_group_name = azurerm_resource_group.avd_poc.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.example.id
  type                = "RemoteApp"
  tags                = azurerm_virtual_desktop_host_pool.example.tags
  friendly_name       = "EXAMPLE-APP"
}

resource "azurerm_virtual_desktop_workspace" "example_workspace" {
  name                = "AVDPOC-EXAMPLE-WORKSPACE"
  location            = "usgovvirginia"
  resource_group_name = azurerm_resource_group.avd_poc.name
  public_network_access_enabled = false
  tags                = azurerm_virtual_desktop_host_pool.example.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "dag_assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.example_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.dag.id
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "remoteapp_assoc" {
  workspace_id         = azurerm_virtual_desktop_workspace.example_workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.remoteapp.id
}

resource "azurerm_private_endpoint" "hostpool_pe" {
  name                = "avdpoc-example-hostpool-pe"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  subnet_id           = azurerm_subnet.avd_pe_subnet.id
  tags                = local.tags

  private_service_connection {
    name                           = "hostpool-psc"
    private_connection_resource_id = azurerm_virtual_desktop_host_pool.example.id
    is_manual_connection           = false
    subresource_names              = ["connection"]
  }
}

resource "azurerm_private_endpoint" "workspace_pe" {
  name                = "avdpoc-example-workspace-pe"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  subnet_id           = azurerm_subnet.avd_pe_subnet.id
  tags                = local.tags

  private_service_connection {
    name                           = "workspace-psc"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.example_workspace.id
    is_manual_connection           = false
    subresource_names              = ["feed"]
  }
}

resource "azurerm_network_interface" "avd_vm_nic" {
  name                = "avd-vm-nic"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
  subnet_id                     = azurerm_subnet.avd_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "avd_vm" {
  name                = "avd-client-vm"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  size                = "Standard_D4as_v5"
  admin_username      = "AzureAdmin"
  admin_password      = "ChangeMe123!" # Change to a secure value or use a secret
  network_interface_ids = [azurerm_network_interface.avd_vm_nic.id]
  tags                = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
    name                 = "avd-client-vm-osdisk"
  }

  source_image_reference {
    publisher = "microsoftwindowsdesktop"
    offer     = "windows-10"
    sku       = "win10-22h2-avd"
    version   = "latest"
  }
}

resource "azurerm_private_endpoint" "workspace_global_pe" {
  name                = "avdpoc-example-workspace-global-pe"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  subnet_id           = azurerm_subnet.avd_pe_subnet.id
  tags                = local.tags

  private_service_connection {
    name                           = "workspace-global-psc"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.example_workspace.id
    is_manual_connection           = false
    subresource_names              = ["global"]
  }
}

resource "azurerm_virtual_network" "bastion_vnet" {
  name                = "bastion-vnet"
  address_space       = ["192.168.0.0/24"]
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.avd_poc.name
  virtual_network_name = azurerm_virtual_network.bastion_vnet.name
  address_prefixes     = ["192.168.0.0/27"]
}

resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags
  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

resource "azurerm_virtual_network_peering" "bastion_to_avd_poc" {
  name                      = "bastion-to-avd-poc"
  resource_group_name       = azurerm_resource_group.avd_poc.name
  virtual_network_name      = azurerm_virtual_network.bastion_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.avd_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "avd_poc_to_bastion" {
  name                      = "avd-poc-to-bastion"
  resource_group_name       = azurerm_resource_group.avd_poc.name
  virtual_network_name      = azurerm_virtual_network.avd_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.bastion_vnet.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  allow_virtual_network_access = true
}

resource "azurerm_private_dns_zone" "wvd_azure_us" {
  name                = "privatelink.wvd.azure.us"
  resource_group_name = azurerm_resource_group.avd_poc.name
}

resource "azurerm_private_dns_zone" "global_wvd_azure_us" {
  name                = "privatelink-global.wvd.azure.us"
  resource_group_name = azurerm_resource_group.avd_poc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "wvd_azure_us_link" {
  name                  = "wvd-azure-us-link"
  resource_group_name   = azurerm_resource_group.avd_poc.name
  private_dns_zone_name = azurerm_private_dns_zone.wvd_azure_us.name
  virtual_network_id    = azurerm_virtual_network.avd_vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "global_wvd_azure_us_link" {
  name                  = "global-wvd-azure-us-link"
  resource_group_name   = azurerm_resource_group.avd_poc.name
  private_dns_zone_name = azurerm_private_dns_zone.global_wvd_azure_us.name
  virtual_network_id    = azurerm_virtual_network.avd_vnet.id
  registration_enabled  = false
}

resource "azurerm_network_interface" "sessionhost1_nic" {
  name                = "sessionhost1-nic"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "sessionhost1" {
  name                = "sessionhost1"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  size                = "Standard_D4as_v5"
  admin_username      = "AzureAdmin"
  admin_password      = "ChangeMe123!" # Change to a secure value or use a secret
  network_interface_ids = [azurerm_network_interface.sessionhost1_nic.id]
  tags                = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
    name                 = "sessionhost1-osdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-avd"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "sessionhost2_nic" {
  name                = "sessionhost2-nic"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.avd_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "sessionhost2" {
  name                = "sessionhost2"
  location            = azurerm_resource_group.avd_poc.location
  resource_group_name = azurerm_resource_group.avd_poc.name
  size                = "Standard_D4as_v5"
  admin_username      = "AzureAdmin"
  admin_password      = "ChangeMe123!" # Change to a secure value or use a secret
  network_interface_ids = [azurerm_network_interface.sessionhost2_nic.id]
  tags                = local.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
    name                 = "sessionhost2-osdisk"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-22h2-avd"
    version   = "latest"
  }
}
