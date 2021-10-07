output "tls_private_key" { 
    value = module.tf-az-vault-server.tls_private_key 
}

output "vault_public_ip" {
    value = module.tf-az-vault-server.vm_public_ip
}

output "vault_private_ip" {
    value = module.tf-az-vault-server.vm_private_ip
}

output "subnet_id" {
    value = module.tf-az-infra.subnet_id
}

output "nsg_id" {
    value = module.tf-az-vault-server.nsg_id
}

output "arg_location" {
    value = module.tf-az-rg.arg_location
}

output "arg_name" {
    value = module.tf-az-rg.arg_name
}

output "arg_id" {
    value = module.tf-az-rg.arg_id
}

output "name_prefix" {
    value = var.name_prefix
}

