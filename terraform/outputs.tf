
output "app_public_ip" {
  description = "Public IP address of the EpicBook frontend VM"
  value       = azurerm_public_ip.frontend.ip_address
}

output "backend_ansible_host" {
  description = "Private IP address for Ansible to reach the backend VM"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "backend_private_ip" {
  description = "Private IP address of the backend VM"
  value       = azurerm_network_interface.backend.private_ip_address
}

output "mysql_fqdn" {
  description = "Private DNS hostname of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.epicbook.fqdn
}

output "resource_group_name" {
  description = "Resource group containing EpicBook production resources"
  value       = azurerm_resource_group.epicbook.name
}
