// Create managed image resource group
resource "azurerm_resource_group" "managed_image_rg" {
  name     = "${var.managed_image_resourcegroup_name}"
  location = "${var.location}"
}

data "azurerm_resource_group" "managed_image_rg" {
  name = "${var.managed_image_resourcegroup_name}"
}
 
data "azurerm_image" "managed_image" {
  depends_on          = [data.azurerm_resource_group.managed_image_rg] 
  name                = "${var.managed_image_name}"
  resource_group_name = "${data.azurerm_resource_group.managed_image_rg.name}"
}

resource "azurerm_resource_group" "terraformrg" {
  name     = "${var.prefix}-rg"
  location = "${var.location}"

  tags = {
    environment = "Terraform deployment"
  }
}