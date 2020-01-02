## VMSS deployment test with MSI enabled in Singapore.  
## AZ:no, PublicLB:yes, MSI:yes, MSI RBAC:yes, Custom Extension:yes

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
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_subnet" "agsubnet" {
  name                 = "ag-subnet"
  virtual_network_name = "${azurerm_virtual_network.terraformvnet.name}"
  resource_group_name  = "${azurerm_resource_group.terraformrg.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_subnet" "agsubnet2" {
  name                 = "ag-subnet2"
  virtual_network_name = "${azurerm_virtual_network.terraformvnet.name}"
  resource_group_name  = "${azurerm_resource_group.terraformrg.name}"
  address_prefix       = "10.0.3.0/24"
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


resource "azurerm_public_ip" "agPIP" {
  name                = "ag-pip"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "Terraform Deployment"
  }
}

resource "azurerm_public_ip" "agPIP2" {
  name                = "ag-pip2"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "Terraform Deployment"
  }
}

resource "azurerm_lb" "terraformnatlb" {
  name                = "terraform-natlb"
  location            = "${azurerm_resource_group.terraformrg.location}"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.PublicLBPIP.id}"
  }
  tags = {
  environment = "Terraform deployment"
  }
}

resource "azurerm_lb_backend_address_pool" "backendpool" {
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  loadbalancer_id     = "${azurerm_lb.terraformnatlb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = "${azurerm_resource_group.terraformrg.name}"
  name                           = "ssh"
  loadbalancer_id                = "${azurerm_lb.terraformnatlb.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}


resource "azurerm_virtual_machine_scale_set" "terraformvmss" {
  name                = "${var.prefix}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  depends_on = [azurerm_application_gateway.network, azurerm_application_gateway.network2]
  upgrade_policy_mode = "Manual"
  overprovision = false
  
  sku {
    name     = "Standard_F2s"
    tier     = "Standard"
    capacity = 0
  }

  os_profile {
    computer_name_prefix = "${var.prefix}"
    admin_username       = "myadmin"
    admin_password       = "Password1234"
  }
  
  os_profile_linux_config {
    disable_password_authentication = false
            ssh_keys {
            path     = "/home/myadmin/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCczY+8XfyQ3vc6kvCUMM10pTWKAUhsvKV82OUK8qjWMnG5De7zUGJ+KeLY75+zxQAZt7gkwUBudDNTK6HmEyUQ9W/q5KmvEqfa641CwFuksj2umXCkIyFcm0mAhAIxcKah8SwVfSl2zJlp/dqoSCBpzGFXEIYp4OtBiQTAjupAeLPYwKtXdUXzjmMzfhSpY4H4EYJzgzt/eS2thYMgOtvv5kr3/Xbee70STNVyoliSUHhW5EpDOmgD7/TRGAy+OqRUoqtyRMDByfRKHT62r+OcmZUpUiylnVllhmQyLYuLCXDZIqRTVfQv0G2QoCIV7CsJ0XG7bmalbp+D/bdgugsN"
        }
  }

  network_profile {
    name    = "ssh_publiclb_profile"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = "${azurerm_subnet.terraformsubnet.id}"
      primary   = true
      load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lbnatpool.id}"]
      application_gateway_backend_address_pool_ids = ["${azurerm_application_gateway.network.backend_address_pool[0].id}","${azurerm_application_gateway.network2.backend_address_pool[0].id}"]
    }
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_profile_data_disk {
    lun = 0
    create_option = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 250
  }

  storage_profile_image_reference {
    # publisher = "Canonical"
    # offer     = "UbuntuServer"
    # sku       = "16.04-LTS"
    # version   = "latest"
    id = "${data.azurerm_image.managed_image.id}"
  }

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

resource "azurerm_role_assignment" "terraformmsirole" {
  scope              = "${azurerm_resource_group.terraformrg.id}"
  role_definition_name = "Contributor"
  principal_id       = "${lookup(azurerm_virtual_machine_scale_set.terraformvmss.identity[0], "principal_id")}"
}

locals {
  backend_address_pool_name      = "${var.prefix}-appg-beap"
  frontend_port_name             = "${var.prefix}-appg-feport"
  frontend_ip_configuration_name = "${var.prefix}-appg-feip"
  http_setting_name              = "${var.prefix}-appg-be-htst"
  listener_name                  = "${var.prefix}-appg-httplstn"
  request_routing_rule_name      = "${var.prefix}-appg-rqrt"
  redirect_configuration_name    = "${var.prefix}-appg-rdrcfg"
  probe_name                     = "${var.prefix}-appg-probe"
}

resource "azurerm_application_gateway" "network" {
  name                = "vmss-appgateway"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${azurerm_subnet.agsubnet.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.agPIP.id}"
    private_ip_address_allocation = "Dynamic"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 9000
    protocol              = "Http"
    request_timeout       = 1
    connection_draining {
      enabled             = true
      drain_timeout_sec   = 10 
    }
    probe_name            = "${local.probe_name}"
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }

  probe {
    name                      = "${local.probe_name}"
    protocol                  = "Http"
    host                      = "127.0.0.1"
    path                      = "/health"
    interval                  = 1
    timeout                   = 1
    unhealthy_threshold       = 2
    pick_host_name_from_backend_http_settings = false
    minimum_servers           = 0
    match {
      body = "Healthy"
      status_code = ["200-399"]
    }
  }
}

locals {
  backend_address_pool_name2      = "${var.prefix}-appg-beap2"
  frontend_port_name2             = "${var.prefix}-appg-feport2"
  frontend_ip_configuration_name2 = "${var.prefix}-appg-feip2"
  http_setting_name2              = "${var.prefix}-appg-be-htst2"
  listener_name2                  = "${var.prefix}-appg-httplstn2"
  request_routing_rule_name2      = "${var.prefix}-appg-rqrt2"
  redirect_configuration_name2    = "${var.prefix}-appg-rdrcfg2"
  probe_name2                     = "${var.prefix}-appg-probe2"
}

resource "azurerm_application_gateway" "network2" {
  name                = "vmss-appgateway2"
  resource_group_name = "${azurerm_resource_group.terraformrg.name}"
  location            = "${azurerm_resource_group.terraformrg.location}"
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration2"
    subnet_id = "${azurerm_subnet.agsubnet2.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name2}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name2}"
    public_ip_address_id = "${azurerm_public_ip.agPIP2.id}"
    private_ip_address_allocation = "Dynamic"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name2}"
  }

  backend_http_settings {
    name                  = "${local.http_setting_name2}"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 9000
    protocol              = "Http"
    request_timeout       = 1
    connection_draining {
      enabled             = true
      drain_timeout_sec   = 10 
    }
    probe_name            = "${local.probe_name2}"
  }

  http_listener {
    name                           = "${local.listener_name2}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name2}"
    frontend_port_name             = "${local.frontend_port_name2}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name2}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name2}"
    backend_address_pool_name  = "${local.backend_address_pool_name2}"
    backend_http_settings_name = "${local.http_setting_name2}"
  }

  probe {
    name                      = "${local.probe_name2}"
    protocol                  = "Http"
    host                      = "127.0.0.1"
    path                      = "/health"
    interval                  = 1
    timeout                   = 1
    unhealthy_threshold       = 2
    pick_host_name_from_backend_http_settings = false
    minimum_servers           = 0
    match {
      body = "Healthy"
      status_code = ["200-399"]
    }
  }
}

output "public_ip_addr" {
  value = azurerm_public_ip.PublicLBPIP.ip_address
}
