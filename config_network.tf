resource "azurerm_virtual_network" "terraformvnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "Terraform Deployment"
  }
}

resource "azurerm_subnet" "terraformsubnet" {
  name                 = "vmss-subnet"
  virtual_network_name = "${azurerm_virtual_network.terraformvnet.name}"
  resource_group_name  = "${azurerm_resource_group.terraformrg.name}"
  address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "agsubnet" {
  name                 = "ag-subnet"
  virtual_network_name = "${azurerm_virtual_network.terraformvnet.name}"
  resource_group_name  = "${azurerm_resource_group.terraformrg.name}"
  address_prefixes       = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "agsubnet2" {
  name                 = "ag-subnet2"
  virtual_network_name = "${azurerm_virtual_network.terraformvnet.name}"
  resource_group_name  = "${azurerm_resource_group.terraformrg.name}"
  address_prefixes       = ["10.0.3.0/24"]
}

resource "azurerm_public_ip" "PublicLBPIP" {
  name                = "publiclb-pip"
  location            = "${azurerm_resource_group.terraformrg.location}"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${azurerm_resource_group.terraformrg.name}"
  tags = {
    environment = "Terraform Deployment"
  }
}
