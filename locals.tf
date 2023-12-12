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
