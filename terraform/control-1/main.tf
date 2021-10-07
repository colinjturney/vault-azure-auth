data "azurerm_subscription" "primary" {
}

data "azuread_client_config" "current" {
}

module "tf-az-rg" {
  source = "../modules/tf-az-rg"

  arg_name      = var.arg_name
  arg_location  = var.arg_location

  tag_creator   = var.tag_creator
}

module "tf-az-infra" {
  source = "../modules/tf-az-infra"

  arg_name      = var.arg_name
  arg_location  = var.arg_location

  vnet_address_space      = var.infra_vnet_address_space
  subnet_address_prefixes = var.infra_subnet_address_prefixes
  name_prefix             = var.name_prefix
  tag_creator             = var.tag_creator

  depends_on = [module.tf-az-rg]
}

module "tf-az-vault-server" {
  source = "../modules/tf-az-vault-server"

  subnet_id        = module.tf-az-infra.subnet_id
  ncg_allow_prefix = var.ncg_allow_prefix

  arg_name      = module.tf-az-rg.arg_name
  arg_location  = module.tf-az-rg.arg_location
  arg_id        = module.tf-az-rg.arg_id

  name_prefix   = var.name_prefix
  tag_creator   = var.tag_creator

  tenant_id       = data.azuread_client_config.current.tenant_id
  subscription_id = data.azurerm_subscription.primary.id

  depends_on = [module.tf-az-rg]
}