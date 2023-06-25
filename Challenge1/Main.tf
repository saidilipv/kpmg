terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create resource group
resource "azurerm_resource_group" "example_rg" {
  name     = "example-resource-group"
  location = "East US2" 
}

# Create Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example_rg.location  
  resource_group_name = azurerm_resource_group.example_rg.name
}

# Create Azure Subnet for the app tier
resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes      = ["10.0.1.0/24"] 
}
resource "azurerm_subnet" "Front_subnet" {
  name                 = "Front-subnet"
  resource_group_name  = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes      = ["10.0.1.0/24"] 
}
resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.example_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes      = ["10.0.1.0/24"] 
}

#network security group
resource "azurerm_network_security_group" "NSG" {
  name                = "my-nsg"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
}
resource "azurerm_network_security_rule" "rule" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example_rg.name
  network_security_group_name = azurerm_network_security_group.NSG.name
}
resource "azurerm_subnet_network_security_group_association" "nsg_app_subnet_assoc"{
    subnet_id                  = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/app-subnet"
    network_security_group_id = azurerm_network_security_group.NSG.id
}
resource "azurerm_subnet_network_security_group_association" "nsg_Front_subnet_assoc"{
    subnet_id                  = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/front-subnet"
    network_security_group_id = azurerm_network_security_group.NSG.id
}
resource "azurerm_subnet_network_security_group_association" "nsg_data_subnet_assoc"{
    subnet_id                  = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/data-subnet"
    network_security_group_id = azurerm_network_security_group.NSG.id
}

# Network interface 

resource "azurerm_network_interface" "App_Nic" {
  count               = 2
  name                = "nic_app${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/app-subnet"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "front_nic" {
  count               = 2
  name                = "nic_fornt${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/front-subnet"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "data_nic" {
  count               = 2
  name                = "nic_data${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Network/virtualNetworks/azurerm_virtual_network.vnet.name/subnets/data-subnet"
    private_ip_address_allocation = "Dynamic"
  }
}

# availability set

resource "azurerm_availability_set" "AVset_app" {
  name                = "App_AVset"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 3
}
resource "azurerm_availability_set" "AVset_front" {
  name                = "fornt_AVset"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 3
}
resource "azurerm_availability_set" "AVset_data" {
  name                = "data_AVset"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 3
}

#VM's 
#front end VM's

resource "azurerm_virtual_machine" "front_vm" {
  count               = 2
  name                = "vm_fornt${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  availability_set_id = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Compute/availabilitySets/front_AVset"
  network_interface_ids = [
    azurerm_network_interface.front_nic[count.index].id,
  ]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
   os_disk   {
     name = "my-vm_osdisk"
     caching             =   "ReadWrite" 
     storage_account_type   =   "Standard_LRS" 
   } 
}

# app VM's

resource "azurerm_virtual_machine" "app_vm" {
  count               = 2
  name                = "vm_app${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  availability_set_id = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Compute/availabilitySets/App_AVset"
  network_interface_ids = [
    azurerm_network_interface.App_Nic[count.index].id,
  ]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
   os_disk   {
     name = "my-vm_osdisk"
     caching             =   "ReadWrite" 
     storage_account_type   =   "Standard_LRS" 
   } 
}

# data VM's

resource "azurerm_virtual_machine" "data_vm" {
  count               = 2
  name                = "vm_data${count.index + 1}"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  availability_set_id = "/subscriptions/SubscriptionID/resourceGroups/azurerm_resource_group.example_rg.name/providers/Microsoft.Compute/availabilitySets/data_AVset"
  network_interface_ids = [
    azurerm_network_interface.data_Nic[count.index].id,
  ]
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
   os_disk   {
     name = "my-vm_osdisk"
     caching             =   "ReadWrite" 
     storage_account_type   =   "Standard_LRS" 
   } 
}

# Load Balancer

# Data ILB
resource "azurerm_lb" "InternalLB_002" {
  name                = "InternalLB_002"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    subnet_id            = azurerm_subnet.data_subnet.id
    private_ip_address   = "10.0.0.10"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool_vm" "example" {
  count               = 2
  loadbalancer_id     = azurerm_lb.InternalLB_002.id
  name                = "backend-pool-vm-${count.index}"
  virtual_machine_ids = [azurerm_network_interface.data_nic[count.index].virtual_machine_id]
}

resource "azurerm_lb_probe" "healthprobeinternal002" {
  loadbalancer_id     = azurerm_lb.InternalLB_002.id
  name                = "my-health-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_lb_rule" "rulesinternal002" {
  loadbalancer_id                = azurerm_lb.InternalLB_002.id
  name                           = "my-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend-ip"
}

# App Load balancer 

resource "azurerm_lb" "InternalLB_002" {
  name                = "InternalLB_002"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend"
    subnet_id            = azurerm_subnet.data_subnet.id
    private_ip_address   = "10.0.0.10"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool_vm" "example" {
  count               = 2
  loadbalancer_id     = azurerm_lb.InternalLB_002.id
  name                = "backend-pool-vm-${count.index}"
  virtual_machine_ids = [azurerm_network_interface.App_Nic_nic[count.index].virtual_machine_id]
}

resource "azurerm_lb_probe" "healthprobeinternal002" {
  loadbalancer_id     = azurerm_lb.InternalLB_002.id
  name                = "my-health-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_lb_rule" "rulesinternal002" {
  loadbalancer_id                = azurerm_lb.InternalLB_002.id
  name                           = "my-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend-ip"
}

# public front load balancer

resource "azurerm_public_ip" "publicLB_IP" {
  name                = "my-public-ip"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "publicLB" {
  name                = "my-lb"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = azurerm_public_ip.publicLB_IP.id
  }
}

resource "azurerm_lb_backend_address_pool_vm" "example" {
  count               = 2
  loadbalancer_id     = azurerm_lb.publicLB_IP.id
  name                = "backend-pool-vm-${count.index}"
  virtual_machine_ids = [azurerm_network_interface.front_nic[count.index].virtual_machine_id]
}

resource "azurerm_lb_probe" "healthprobepublic" {
  loadbalancer_id     = azurerm_lb.publicLB.id
  name                = "my-health-probe"
  protocol            = "Http"
  port                = 80
  request_path        = "/"
}

resource "azurerm_lb_rule" "rulepublic" {
  loadbalancer_id                = azurerm_lb.publicLB.id
  name                           = "my-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend-ip"
}