
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-epicbook-tfstate"
    storage_account_name = "epicbookstate2610161604"
    container_name       = "tfstate"
    key                  = "epicbook-austriaeast.tfstate"
    use_azuread_auth     = true
  }
}
