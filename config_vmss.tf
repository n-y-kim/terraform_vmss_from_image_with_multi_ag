resource "azurerm_linux_virtual_machine_scale_set" "terraformvmss" {
  name                = "${var.prefix}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  depends_on = [azurerm_application_gateway.network, azurerm_application_gateway.network2]
  //upgrade_policy_mode = "Manual"
  overprovision = false
  sku = "Standard_DS2_v2"
  instances = 2
  admin_username = "azureuser"
  admin_password = "Password1234!"
  disable_password_authentication = false
  source_image_id = "${data.azurerm_image.managed_image.id}"
  
  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  data_disk {
    caching           = "ReadWrite"
    //create_option     = "FromImage"
    storage_account_type = "Premium_LRS"
    disk_size_gb      = 250
    lun              = 0
  }
  # sku {
  #   name     = "Standard_F2s"
  #   tier     = "Standard"
  #   capacity = 1
  # }

  # os_profile {
  #   computer_name_prefix = "${var.prefix}"
  #   admin_username       = "myadmin"
  #   admin_password       = "Password1234"
  # }
  
  # os_profile_linux_config {
  #   disable_password_authentication = false
  #           ssh_keys {
  #           path     = "/home/myadmin/.ssh/authorized_keys"
  #           key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCczY+8XfyQ3vc6kvCUMM10pTWKAUhsvKV82OUK8qjWMnG5De7zUGJ+KeLY75+zxQAZt7gkwUBudDNTK6HmEyUQ9W/q5KmvEqfa641CwFuksj2umXCkIyFcm0mAhAIxcKah8SwVfSl2zJlp/dqoSCBpzGFXEIYp4OtBiQTAjupAeLPYwKtXdUXzjmMzfhSpY4H4EYJzgzt/eS2thYMgOtvv5kr3/Xbee70STNVyoliSUHhW5EpDOmgD7/TRGAy+OqRUoqtyRMDByfRKHT62r+OcmZUpUiylnVllhmQyLYuLCXDZIqRTVfQv0G2QoCIV7CsJ0XG7bmalbp+D/bdgugsN"
  #       }
  # }

  network_interface {
    name    = "ssh_publiclb_profile"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = "${azurerm_subnet.terraformsubnet.id}"
      primary   = true
      load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lbnatpool.id}"]
      application_gateway_backend_address_pool_ids = [
        tolist(azurerm_application_gateway.network.backend_address_pool)[0].id,
        tolist(azurerm_application_gateway.network2.backend_address_pool)[0].id
      ]
    }
  }

  # storage_profile_data_disk {
  #   lun = 0
  #   create_option = "FromImage"
  #   managed_disk_type = "Premium_LRS"
  #   disk_size_gb      = 250
  # }

  # storage_profile_image_reference {
  #   # publisher = "Canonical"
  #   # offer     = "UbuntuServer"
  #   # sku       = "16.04-LTS"
  #   # version   = "latest"
  #   id = "${data.azurerm_image.managed_image.id}"
  # }

  identity {
    type = "SystemAssigned"
  }
  extension {
    name                 = "bootstrap"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"

    settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/bedro96/terraform_vmss_from_image_with_ag/master/setup.sh"],
        "commandToExecute": "/bin/bash ./setup.sh"
    }
    SETTINGS
  }
  tags = {
    environment = "Terraform deployment"
    EnablePendingDeletion = true
  }
}
