output "tls_private_key" { 
    value = module.tf-az-vault-client.tls_private_key 
}

output "vm_public_ip" {
    value = module.tf-az-vault-client.vm_public_ip
}

output "nsg_id" {
    value = module.tf-az-vault-client.nsg_id
}