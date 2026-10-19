
variable "location" {
  description = "Azure region for EpicBook resources"
  type        = string
  default     = "austriaeast"
}

variable "project_name" {
  description = "Prefix for EpicBook resource names"
  type        = string
  default     = "epicbook"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "admin_username" {
  description = "Linux administrator username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the administrator SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "admin_source_cidr" {
  description = "Public IP CIDR allowed to SSH to the VMs"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2as_v5"
}

variable "mysql_admin_username" {
  description = "Administrator username for MySQL Flexible Server"
  type        = string
  default     = "epicbookadmin"
}

variable "mysql_admin_password" {
  description = "Administrator password for MySQL Flexible Server"
  type        = string
  sensitive   = true
}

variable "admin_source_cidrs" {
  description = "Public IPv4 CIDRs permitted to SSH into the VMs"
  type        = list(string)
}
