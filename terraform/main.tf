
# Resource group for EpicBook production
resource "azurerm_resource_group" "epicbook" {
  name     = "rg-epicbook-app-prod-ae"
  location = var.location

  tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "Terraform"
  }
}

# Virtual network
resource "azurerm_virtual_network" "epicbook" {
  name                = "vnet-epicbook-prod"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

# Public-facing frontend subnet
resource "azurerm_subnet" "frontend" {
  name                 = "snet-frontend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Private backend subnet
resource "azurerm_subnet" "backend" {
  name                 = "snet-backend"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.20.2.0/24"]
}

# Dedicated subnet for Azure Database for MySQL private networking
resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.epicbook.name
  virtual_network_name = azurerm_virtual_network.epicbook.name
  address_prefixes     = ["10.20.3.0/24"]

  delegation {
    name = "mysql-flexible-server-delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}





# Frontend network security group
resource "azurerm_network_security_group" "frontend" {
  name                = "nsg-epicbook-frontend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_source_cidrs
    destination_address_prefix = "*"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

# Backend network security group
resource "azurerm_network_security_group" "backend" {
  name                = "nsg-epicbook-backend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "Allow-App-From-Frontend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.20.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Admin"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.admin_source_cidrs
    destination_address_prefix = "*"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}




# Apply frontend security rules to the frontend subnet
resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

# Apply backend security rules to the backend subnet
resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend.id
}






# Public IP for the frontend web server
resource "azurerm_public_ip" "frontend" {
  name                = "pip-epicbook-frontend"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

# Network interface for the frontend VM
resource "azurerm_network_interface" "frontend" {
  name                = "nic-epicbook-frontend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend.id
  }

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

# Private-only network interface for the backend VM
resource "azurerm_network_interface" "backend" {
  name                = "nic-epicbook-backend"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}





# Frontend Ubuntu VM
resource "azurerm_linux_virtual_machine" "frontend" {
  name                = "vm-epicbook-frontend"
  computer_name       = "epicfrontend"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.frontend.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-epicbook-frontend"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    role        = "frontend"
  }
}

# Backend Ubuntu VM
resource "azurerm_linux_virtual_machine" "backend" {
  name                = "vm-epicbook-backend"
  computer_name       = "epicbackend"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.backend.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "osdisk-epicbook-backend"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    project     = var.project_name
    environment = var.environment
    role        = "backend"
  }
}





# Private DNS zone for Azure Database for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  name                = "epicbook-mysql-prod-ae.private.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.epicbook.name

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

# Link the private DNS zone to the EpicBook virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "link-epicbook-mysql-vnet"
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = azurerm_virtual_network.epicbook.id
  resource_group_name   = azurerm_resource_group.epicbook.name
  registration_enabled  = false
}

# Azure Database for MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "epicbook" {
  name                = "mysql-epicbook-prod-ae-261016"
  resource_group_name = azurerm_resource_group.epicbook.name
  location            = azurerm_resource_group.epicbook.location

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password

  backup_retention_days = 7
  delegated_subnet_id   = azurerm_subnet.database.id
  private_dns_zone_id   = azurerm_private_dns_zone.mysql.id
  public_network_access = "Disabled"

  sku_name = "B_Standard_B1ms"
  version  = "8.0.21"
  storage {
    size_gb = 20
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql
  ]

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}






resource "azurerm_network_security_group" "database" {
  name                = "nsg-epicbook-database"
  location            = azurerm_resource_group.epicbook.location
  resource_group_name = azurerm_resource_group.epicbook.name

  security_rule {
    name                       = "Allow-MySQL-From-Backend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.20.2.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-MySQL-From-Other-VNet"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.20.0.0/16"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}
