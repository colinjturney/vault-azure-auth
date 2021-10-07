resource "azurerm_virtual_network" "virtual_network" {
    name = "${var.name_prefix}-network"
    
    location            = var.arg_location
    resource_group_name = var.arg_name
    
    address_space = var.vnet_address_space
    
    tags = {
        creator = var.tag_creator
    }
}

resource "azurerm_subnet" "subnet" {
    name = "${var.name_prefix}-subnet"
    
    resource_group_name     = var.arg_name

    address_prefixes        = var.subnet_address_prefixes
    virtual_network_name    = azurerm_virtual_network.virtual_network.name    
}