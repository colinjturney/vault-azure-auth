resource "azurerm_public_ip" "publicip" {
    name    = "${var.name_prefix}-publicip-vault"
    
    location            = var.arg_location
    resource_group_name = var.arg_name

    allocation_method            = "Dynamic"

    tags = {
        creator = var.tag_creator
    }
}

resource "azurerm_network_security_group" "nsg" {
    name                = "${var.name_prefix}-nsg"
   
    location            = var.arg_location
    resource_group_name = var.arg_name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = var.ncg_allow_prefix
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Vault"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8200"
        source_address_prefix      = var.ncg_allow_prefix
        destination_address_prefix = "*"
    }

    tags = {
        creator = var.tag_creator
    }
}

resource "azurerm_network_interface" "nic" {
    name                        = "${var.name_prefix}-nic-vault"

    location                    = var.arg_location
    resource_group_name         = var.arg_name

    ip_configuration {
        name                          = "${var.name_prefix}-nic-config-vault"
        subnet_id                     = var.subnet_id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.publicip.id
    }

    tags = {
        creator = var.tag_creator
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nic-sg-ass" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group_name = var.arg_name
    }

    byte_length = 8
}

resource "azurerm_storage_account" "sa" {
    name                        = "diag${random_id.randomId.hex}"
    
    resource_group_name         = var.arg_name
    location                    = var.arg_location
    
    account_replication_type    = "LRS"
    account_tier                = "Standard"

    tags = {
        creator = var.tag_creator
    }
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "azurerm_linux_virtual_machine" "vm" {
    name                  = "${var.name_prefix}-vm-vault"

    location              = var.arg_location
    resource_group_name   = var.arg_name
    
    network_interface_ids = [azurerm_network_interface.nic.id]
    size                  = "Standard_B2s"

    os_disk {
        name                    = "${var.name_prefix}-vm-disk-vault"
        caching                 = "ReadWrite"
        storage_account_type    = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "vault"
    admin_username = "azureuser"
    disable_password_authentication = true

    custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)

    identity {
        type = "SystemAssigned"
    }

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.ssh.public_key_openssh
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.sa.primary_blob_endpoint
    }

    tags = {
        creator = var.tag_creator
    }
}

# Data template Bash bootstrapping file
data "template_file" "linux-vm-cloud-init" {
    template = file("${path.module}/vault-server.sh")
    vars = {
        tenant_id = var.tenant_id
        resource_group = var.arg_name
        subscription_id = var.subscription_id
    }
}

resource "local_file" "key" {
    content = tls_private_key.ssh.private_key_pem 
    filename = "${path.root}/vault-server.pem"
    file_permission = "0400"
}


resource "azurerm_role_definition" "vault_server" {
    name = "${var.name_prefix}-vm-vault-role"
    scope = var.arg_id
    description = "A custom role for Vault server"

    permissions {
        actions = ["Microsoft.Compute/virtualMachines/*/read"
                , "Microsoft.Compute/virtualMachineScaleSets/*/read"
                ]
    }
}

resource "azurerm_role_assignment" "vault_server" {
    scope = var.arg_id
    role_definition_id = azurerm_role_definition.vault_server.role_definition_resource_id
    principal_id = azurerm_linux_virtual_machine.vm.identity[0].principal_id   
}