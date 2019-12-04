
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
}

resource "azurerm_subnet" "main" {
  count = 2

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
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

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
  security_rule {
    access = "Allow"
    direction = "Inbound"
    name = "tomcat_access"
    priority = 1000
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "8080"
    source_address_prefix = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    access = "Allow"
    direction = "Outbound"
    name = "outbound_access"
    priority = 1000
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
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
  }
  os_profile {
    computer_name = "hostname"
    admin_username = "testadmin"
    custom_data = templatefile("${path.module}/prepare_azure_vm.sh", {
        azure_db_endpoint = "jdbc:postgresql://${azurerm_postgresql_server.example.name}.postgres.database.azure.com:5432/${var.db_username}@${azurerm_postgresql_server.example.name}",
        azure_db_username = "${var.db_username}@${azurerm_postgresql_server.example.name}",
        azure_db_password = "${var.db_password}"
      })
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = var.ssh_public_key
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


resource "azurerm_postgresql_server" "example" {
  name                = "ccwebapppostgresql"
  location            = "${azurerm_resource_group.ccwebapp.location}"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = var.db_username
  administrator_login_password = var.db_password
  version                      = "9.5"
  ssl_enforcement              = "Disabled"
}

resource "azurerm_postgresql_virtual_network_rule" "example" {
  name                                 = "postgresql-vnet-rule"
  resource_group_name                  = "${azurerm_resource_group.ccwebapp.name}"
  server_name                          = "${azurerm_postgresql_server.example.name}"
  subnet_id                            = "${azurerm_subnet.dbsub.id}"
  ignore_missing_vnet_service_endpoint = true
}

# DB SUBNET
resource "azurerm_subnet" "dbsub" {
  name                 = "dbsubn"
  resource_group_name  = "${azurerm_resource_group.ccwebapp.name}"
  virtual_network_name = "${azurerm_virtual_network.app_network.name}"
  address_prefix       = "${var.subnet_addresses[2]}"
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_postgresql_firewall_rule" "example" {
  name                = "office"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
  server_name         = "${azurerm_postgresql_server.example.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

# resource "azurerm_storage_blob" "storage_blob" {
#   name = "webapp.${var.env}.${var.domainName}"
#   resource_group_name = "${azurerm_resource_group.storage_blob.name}"
#   storage_account_name = "${azurerm_storage_account.storage_blob.name}"
#   storage_container_name = "${azurerm_storage_container.storage_blob.name}"
#   type                   = "Block"
#   #source                 = "some-local-file.zip"
# }

#Load Balancer

#Associate both Vm to the same resource group

# resource "azurerm_virtual_network" "load_balancer" {
#   name                = "acctvn"
#   address_space       = [var.network_address]
#   location            = "${azurerm_resource_group.ccwebapp.location}"
#   resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
# }

# resource "azurerm_subnet" "load_balancer" {
#   count=2 
#   name                 = "acctsub"
#   resource_group_name  = "${azurerm_resource_group.ccwebapp.name}"
#   virtual_network_name = "${azurerm_virtual_network.load_balancer.name}"
#   address_prefix       = "var.subnet_addresses[count.index]"
# }

resource "azurerm_public_ip" "load_balancer" {
  name                = "PublicIPForLB"
  location            = var.region
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
  allocation_method   = "Static"
  #domain_name_label   = "${azurerm_resource_group.ccwebapp.name}"
   tags = {
    environment = "staging"
  }
}

resource "azurerm_lb" "load_balancer" {
  name                = "TestLoadBalancer"
  location            = var.region
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.load_balancer.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "load_balancer" {
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
  loadbalancer_id     = "${azurerm_lb.load_balancer.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_rule" "load_balancer" {
  resource_group_name            = "${azurerm_resource_group.ccwebapp.name}"
  loadbalancer_id                = "${azurerm_lb.load_balancer.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
}

# resource "azurerm_lb_nat_pool" "load_balancer" {
#   resource_group_name            = "${azurerm_resource_group.ccwebapp.name}"
#   name                           = "ssh"
#   loadbalancer_id                = "${azurerm_lb.load_balancer.id}"
#   protocol                       = "Tcp"
#   frontend_port_start            = 50000
#   frontend_port_end              = 50119
#   backend_port                   = 22
#   frontend_ip_configuration_name = "PublicIPAddress"
# }

# resource "azurerm_lb_probe" "load_balancer" {
#   resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
#   loadbalancer_id     = "${azurerm_lb.load_balancer.id}"
#   name                = "http-probe"
#   protocol            = "Http"
#   request_path        = "/health"
#   port                = 8080
# }

# resource "azurerm_virtual_machine_scale_set" "load_balancer" {
#   name                = "mytestscaleset-1"
#   location            = "${azurerm_resource_group.ccwebapp.location}"
#   resource_group_name = "${azurerm_resource_group.ccwebapp.name}"

#   # automatic rolling upgrade
#   automatic_os_upgrade = true
#   upgrade_policy_mode  = "Rolling"

#   rolling_upgrade_policy {
#     max_batch_instance_percent              = 20
#     max_unhealthy_instance_percent          = 20
#     max_unhealthy_upgraded_instance_percent = 5
#     pause_time_between_batches              = "PT0S"
#   }

#   # required when using rolling upgrade policy
#   health_probe_id = "${azurerm_lb_probe.load_balancer.id}"

#   sku {
#     name     = "Standard_F2"
#     tier     = "Standard"
#     capacity = 2
#   }

#   storage_profile_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }

#   storage_profile_os_disk {
#     name              = ""
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   storage_profile_data_disk {
#     lun           = 0
#     caching       = "ReadWrite"
#     create_option = "Empty"
#     disk_size_gb  = 10
#   }

#   os_profile {
#     computer_name_prefix = "testvm"
#     admin_username       = "myadmin"
#   }

#   os_profile_linux_config {
#     disable_password_authentication = true

#     ssh_keys {
#         key_data = var.ssh_public_key
#         path = "/home/myadmin/.ssh/authorized_keys"
#     }
#   }

#   network_profile {
#     name    = "terraformnetworkprofile"
#     primary = true

#     ip_configuration {
#       name                                   = "IPConfiguration"
#       primary                                = true
#       subnet_id                              = azurerm_subnet.main.0.id
#       load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.load_balancer.id}"]
#       load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.load_balancer.id}"]
#     }
#   }

#   tags = {
#     environment = "staging" 
#   }
# }

# resource "azurerm_autoscale_setting" "load_balancer" {
#   name                = "myAutoscaleSetting"
#   resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
#   location            = "${azurerm_resource_group.ccwebapp.location}"
#   target_resource_id  = "${azurerm_virtual_machine_scale_set.load_balancer.id}"

#   profile {
#     name = "Weekends"

#     capacity {
#       default = 1
#       minimum = 1
#       maximum = 10FQDN
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = "${azurerm_virtual_machine_scale_set.load_balancer.id}"
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "GreaterThan"
#         threshold          = 90
#       }

#       scale_action {
#         direction = "Increase"
#         type      = "ChangeCount"
#         value     = "2"
#         cooldown  = "PT1M"
#       }
#     }

#     rule {
#       metric_trigger {
#         metric_name        = "Percentage CPU"
#         metric_resource_id = "${azurerm_virtual_machine_scale_set.load_balancer.id}"
#         time_grain         = "PT1M"
#         statistic          = "Average"
#         time_window        = "PT5M"
#         time_aggregation   = "Average"
#         operator           = "LessThan"
#         threshold          = 10
#       }

#       scale_action {
#         direction = "Decrease"
#         type      = "ChangeCount"
#         value     = "2"
#         cooldown  = "PT1M"
#       }
#     }

#     recurrence {
#       frequency = "Week"
#       timezone  = "Pacific Standard Time"
#       days      = ["Saturday", "Sunday"]
#       hours     = [12]
#       minutes   = [0]
#     }
#   }

#   notification {
#     email {
#       send_to_subscription_administrator    = true
#       send_to_subscription_co_administrator = true
#       custom_emails                         = ["anglekar.s@husky.neu.edu"]
#     }
#   }
# }

#Firewall
resource "azurerm_virtual_network" "firewall" {
  name                = "testvnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.ccwebapp.location}"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = "${azurerm_resource_group.ccwebapp.name}"
  virtual_network_name = "${azurerm_virtual_network.firewall.name}"
  address_prefix       =  "10.0.1.0/24"
}

resource "azurerm_public_ip" "firewall" {
  name                = "testpip"
  location            = "${azurerm_resource_group.ccwebapp.location}"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "testfirewall"
  location            = "${azurerm_resource_group.ccwebapp.location}"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = "${azurerm_subnet.firewall.id}"
    public_ip_address_id = "${azurerm_public_ip.firewall.id}"
  }
}

resource "azurerm_firewall_application_rule_collection" "firewall" {
  name                = "testcollection"
  azure_firewall_name = "${azurerm_firewall.firewall.name}"
  resource_group_name = "${azurerm_resource_group.ccwebapp.name}"
  priority            = 100
  action              = "Allow"

  rule {
    name = "testrule"

    source_addresses = [
      "10.0.0.0/16",
    ]

    target_fqdns = [
      "*.google.com",
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}
