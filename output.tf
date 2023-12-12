output "public_ip_addr" {
  value = azurerm_public_ip.PublicLBPIP.ip_address
}
