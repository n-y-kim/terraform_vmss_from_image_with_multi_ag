resource "azurerm_role_assignment" "terraformmsirole" {
  scope              = "${azurerm_resource_group.terraformrg.id}"
  role_definition_name = "Contributor"
  principal_id       = "${lookup(azurerm_linux_virtual_machine_scale_set.terraformvmss.identity[0], "principal_id")}"
}