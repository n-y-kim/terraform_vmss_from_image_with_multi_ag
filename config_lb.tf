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
  //resource_group_name = "${azurerm_resource_group.terraformrg.name}"
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