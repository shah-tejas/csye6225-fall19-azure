
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

#Storage_blob
#In Azure Blob you have a Storage Account, within that storage account you can store Blobs,
#Files (think shared drive), Tables and Queues. 
#Within the Blobs you have logical groupings called Containers. 
#Containers are roughly equivalent to AWS S3 Buckets.
resource "azurerm_resource_group" "storage_blob" {
  name     = "storage_blob-resources"
  location = "${var.region}"
}

resource "azurerm_storage_account" "storage_blob" {
  name                     = "azure_storage_acc"
  resource_group_name      = "${azurerm_resource_group.storage_blob.name}"
  location                 = "${azurerm_resource_group.storage_blob.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_blob" {
  name                  = "content"
  resource_group_name   = "${azurerm_resource_group.storage_blob.name}"
  storage_account_name  = "${azurerm_storage_account.storage_blob.name}"
  container_access_type = "private"
}

resource "azurerm_storage_blob" "storage_blob" {
  name = "webapp.${var.env}.${var.domainName}"
  resource_group_name = "${azurerm_resource_group.storage_blob.name}"
  storage_account_name = "${azurerm_storage_account.storage_blob.name}"
  storage_container_name = "${azurerm_storage_container.storage_blob.name}"
  type                   = "Block"
  source                 = "some-local-file.zip"
}