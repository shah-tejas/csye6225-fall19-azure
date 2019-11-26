
# Configure the provider
provider "azurerm" {}

# Create the resource group
resource "azurerm_resource_group" "ccwebapp" {
  location = "${var.region}"
  name = "ccwebapp_infrastructure"
}

resource "azurerm_virtual_network" "app_network" {
  address_space = ["${var.network_address}"]
  location = "${azurerm_resource_group.ccwebapp.location}"
  name = "app_virtual_network"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"

  subnet {
    address_prefix = "${var.subnet_addresses[0]}"
    name = "subnet1"
  }

  subnet {
    address_prefix = "${var.subnet_addresses[1]}"
    name = "subnet2"
  }

  subnet {
    address_prefix = "${var.subnet_addresses[2]}"
    name = "subnet3"
  }
}