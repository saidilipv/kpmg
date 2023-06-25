#Setting up the Azure Provider and Resource Group:

# Define Azure provider
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

#Presentation Layer:

# Create Azure Load Balancer for web tier
resource "azurerm_lb" "web_lb" {
  name                = "web-lb"
  location            = azurerm_resource_group.example_rg.location
  resource_group_name = azurerm_resource_group.example_rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.web_lb_public_ip.id
  }
}

# Create Azure Virtual Machines for web tier
resource "azurerm_virtual_machine" "web_instances" {
  count                 = 2 
  name                  = "web-vm-${count.index}"
  location              = azurerm_resource_group.example_rg.location 
  resource_group_name   = azurerm_resource_group.example_rg.name
  network_interface_ids = [azurerm_network_interface.web_nic.id]
  vm_size               = "Standard_B1s"  
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

#Application Layer

resource "azurerm_virtual_machine" "app_instances" {
  count                 = 2  
  name                  = "app-vm-${count.index}"
  location              = azurerm_resource_group.example_rg.location   
  resource_group_name   = azurerm_resource_group.example_rg.name
  network_interface_ids = [azurerm_network_interface.app_nic.id]
  vm_size               = "Standard_B2s" 
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

#Data base layer

resource "azurerm_sql_server" "database_server" {
  name                         = "database-server"
  resource_group_name          = azurerm_resource_group.example_rg.name
  location                     =azurerm_resource_group.example_rg.location   
  version                      = "12.0"
  administrator_login          = "adminuser"
  administrator_login_password = "password123"
}

resource "azurerm_sql_database" "database" {
  name                         = "example-db"
  resource_group_name          = azurerm_resource_group.example_rg.name
  location                     = azurerm_resource_group.example_rg.location   
  server_name                  = azurerm_sql_server.database_server.name
  edition                      = "Basic"
  requested_service_objective_name = "Basic"
  collation                    = "SQL_Latin1_General_CP1_CI_AS"
}

#3-Layers connections

resource "azurerm_sql_virtual_network_rule" "app_network_rule" {
  name                = "app-network-rule"
  server_name         = azurerm_sql_server.database_server.name
  resource_group_name = azurerm_resource_group.example_rg.name
  subnet_id           = azurerm_subnet.app_subnet.id
}

#  web tier to the application tier
resource "azurerm_lb_backend_address_pool" "web_backend_pool" {
  name                = "web-backend-pool"
  loadbalancer_id     = azurerm_lb.web_lb.id
  resource_group_name = azurerm_resource_group.example_rg.name

  backend_addresses {
    ip_address = azurerm_virtual_machine.web_instances.*.private_ip_address
  }
}

#  application tier to the database tier
resource "azurerm_virtual_machine_extension" "app_db_extension" {
  name                 = "app-db-extension"
  virtual_machine_id   = azurerm_virtual_machine.app_instances[0].id
  resource_group_name  = azurerm_resource_group.example_rg.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update && sudo apt-get install -y mysql-client"
    }
  SETTINGS
}

# Configure database connection string in the application tier
resource "azurerm_virtual_machine_extension" "app_db_connection" {
  name                 = "app-db-connection"
  virtual_machine_id   = azurerm_virtual_machine.app_instances[0].id
  resource_group_name  = azurerm_resource_group.example_rg.name
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "echo 'export DB_CONNECTION_STRING=<YOUR_DATABASE_CONNECTION_STRING>' >> /etc/environment"
    }
  SETTINGS
}