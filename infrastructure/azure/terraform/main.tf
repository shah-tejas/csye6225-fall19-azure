
# Configure the provider
provider "azurerm" {}

# Create the resource group
resource "azurerm_resource_group" "ccwebapp" {
  location = var.region
  name = "ccwebapp_infrastructure"
}

resource "azurerm_virtual_network" "app_network" {
  address_space = [var.network_address]
  location = azurerm_resource_group.ccwebapp.location
  name = "app_virtual_network"
  resource_group_name = azurerm_resource_group.ccwebapp.name

  # subnet {
  #   address_prefix = "${var.subnet_addresses[0]}"
  #   name = "subnet1"
  # }

  # subnet {
  #   address_prefix = "${var.subnet_addresses[1]}"
  #   name = "subnet2"
  # }

  # subnet {
  #   address_prefix = "${var.subnet_addresses[2]}"
  #   name = "subnet3"
  # }
}

resource "azurerm_subnet" "main" {
  count = 3

  name = "subnet-${count.index}"
  resource_group_name = azurerm_resource_group.ccwebapp.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefix = var.subnet_addresses[count.index]
}


resource "azurerm_network_interface" "main" {
  name = "ccwebapp-nic"
  location = azurerm_resource_group.ccwebapp.location
  resource_group_name = azurerm_resource_group.ccwebapp.name
  network_security_group_id = azurerm_network_security_group.network_sg.id

  ip_configuration {
    name = "testconfiguration1"
    subnet_id = azurerm_subnet.main.0.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.network_public_ip.id
  }

  depends_on = [azurerm_subnet.main]
}

resource "azurerm_public_ip" "network_public_ip" {
  name = "vm_public_ip"
  resource_group_name = azurerm_resource_group.ccwebapp.name
  location = var.region
  allocation_method = "Dynamic"
}

resource "azurerm_network_security_group" "network_sg" {
  name = "network_security_group"
  resource_group_name = azurerm_resource_group.ccwebapp.name
  location = var.region
  security_rule {
    access = "Allow"
    direction = "Inbound"
    name = "ssh_access"
    priority = 1001
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
}

data "azurerm_image" "custom" {
  name_regex                = "csye6225_*"
  resource_group_name = "myResourceGroup"
  sort_descending = true
}

resource "azurerm_virtual_machine" "main" {
  name = "ccwebapp-vm"
  location = var.region
  resource_group_name = azurerm_resource_group.ccwebapp.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size = "Standard_B1s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.custom.id}"
  }

  storage_os_disk {
    name = "myosdisk1"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Standard_LRS"
//    image_uri = data.azurerm_image.custom.id
  }
  os_profile {
    computer_name = "hostname"
    admin_username = "testadmin"
//    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("/home/tejas/.ssh/azure_key.pub")
      path = "/home/testadmin/.ssh/authorized_keys"
    }
  }
  tags = {
    environment = "staging"
  }
}

#Storage_blob
#In Azure Blob you have a Storage Account, within that storage account you can store Blobs,
#Files (think shared drive), Tables and Queues. 
#Within the Blobs you have logical groupings called Containers. 
#Containers are roughly equivalent to AWS S3 Buckets.
//resource "azurerm_resource_group" "storage_blob" {
//  name     = "storage_blob-resources"
//  location = "${var.region}"
//}
//
//resource "azurerm_storage_account" "storage_blob" {
//  name                     = "azure_storage_acc"
//  resource_group_name      = "${azurerm_resource_group.storage_blob.name}"
//  location                 = "${azurerm_resource_group.storage_blob.location}"
//  account_tier             = "Standard"
//  account_replication_type = "LRS"
//
//  # rule {
//  #   name = "rule_lc"
//  #   enabled = true
//  #   type = "Lifecycle"
//  #   definition {
//  #     filters {
//  #       prefix_match = ["container1/wibble"]
//  #       blob_types = ["blockBlob"]
//  #     }
//  #     actions = {
//  #       base_blob {
//  #         tier_to_cool {
//  #           days_after_modification_greater_than = 30
//  #         }
//  #         tier_to_archive {
//  #           days_after_modification_greater_than = 90
//  #         }
//  #         delete {
//  #             days_after_modification_greater_than = 2555
//  #         }
//  #       snapshot {
//  #         delete {
//  #           days_after_creation_greater_than = 90
//  #         }
//  #       }
//  #     }
//  #   }
//  # }
//  # }
//}

//resource "azurerm_storage_container" "storage_blob" {
//  name                  = "content"
//  resource_group_name   = "${azurerm_resource_group.storage_blob.name}"
//  storage_account_name  = "${azurerm_storage_account.storage_blob.name}"
//  container_access_type = "private"
//}
//
//resource "azurerm_storage_blob" "storage_blob" {
//  name = "webapp.${var.env}.${var.domainName}"
//  resource_group_name = "${azurerm_resource_group.storage_blob.name}"
//  storage_account_name = "${azurerm_storage_account.storage_blob.name}"
//  storage_container_name = "${azurerm_storage_container.storage_blob.name}"
//  type                   = "Block"
//  #source                 = "some-local-file.zip"
//}