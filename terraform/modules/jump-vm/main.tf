resource "azurerm_public_ip" "jump" {
  name                = "${var.vm_name}-public-pip"
  location            = var.location
  resource_group_name = var.resource_group_name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    Environment = "dev"
    Project     = "online-boutique"
    Purpose     = "Private AKS administration"
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_network_interface" "jump" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jump.id
  }
}


resource "azurerm_linux_virtual_machine" "jump" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name

  size = "Standard_D2s_v3"

  admin_username = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.jump.id
  ]

  disable_password_authentication = true

  custom_data = base64encode(
  templatefile("${path.module}/cloud-init.yaml", {
    ssh_public_key     = var.public_key
  })
)

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.public_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}


resource "azurerm_network_security_group" "jump" {
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface_security_group_association" "jump" {
  network_interface_id      = azurerm_network_interface.jump.id
  network_security_group_id = azurerm_network_security_group.jump.id
}


resource "azurerm_role_assignment" "jump_vm_acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_linux_virtual_machine.jump.identity[0].principal_id
  skip_service_principal_aad_check = true
}