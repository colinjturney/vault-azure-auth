data "azurerm_subscription" "primary" {
}

data "azuread_client_config" "current" {
}

data "terraform_remote_state" "control-1" {
  backend = "local"

  config = {
    path = "${path.cwd}/../control-1/terraform.tfstate"
  }
}

module "tf-az-vault-client" {
  source = "../modules/tf-az-vault-client"

  subnet_id        = data.terraform_remote_state.control-1.outputs.subnet_id
  nsg_allow_prefix = var.nsg_allow_prefix

  arg_name      = data.terraform_remote_state.control-1.outputs.arg_name
  arg_location  = data.terraform_remote_state.control-1.outputs.arg_location
  arg_id        = data.terraform_remote_state.control-1.outputs.arg_id

  vault_private_ip = data.terraform_remote_state.control-1.outputs.vault_private_ip

  name_prefix   = var.name_prefix
  tag_creator   = var.tag_creator

}