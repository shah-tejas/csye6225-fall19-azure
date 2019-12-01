
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

  ip_configuration {
    name = "testconfiguration1"
    subnet_id = azurerm_subnet.main.0.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [azurerm_subnet.main]
}

data "azurerm_image" "custom" {
  name_regex                = "csye6225_*"
  resource_group_name = "myResourceGroup"
  sort_descending = true
}

resource "azurerm_virtual_machine" "main" {
  name = "ccwebapp-vm"
  location = azurerm_resource_group.ccwebapp.location
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
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
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

  # rule {
  #   name = "rule_lc"
  #   enabled = true
  #   type = "Lifecycle"
  #   definition {
  #     filters {
  #       prefix_match = ["container1/wibble"]
  #       blob_types = ["blockBlob"]
  #     }
  #     actions = {
  #       base_blob {
  #         tier_to_cool {
  #           days_after_modification_greater_than = 30
  #         }
  #         tier_to_archive { 
  #           days_after_modification_greater_than = 90
  #         }
  #         delete {
  #             days_after_modification_greater_than = 2555
  #         }
  #       snapshot {
  #         delete {
  #           days_after_creation_greater_than = 90
  #         }
  #       }
  #     }
  #   }
  # }
  # }
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
  #source                 = "some-local-file.zip"
}

#FIREWALL
resource "azurerm_resource_group" "example" {
  name     = "firewall"
  location = "West US"
}

resource "azurerm_template_deployment" "example"{
  name                = "firewall_template"
  resource_group_name = "${azurerm_resource_group.example.name}"
  template_body = <<DEPLOY
  {
    "Parameters": {
            "IPtoBlock1": {
                "Description": "IPAddress to be blocked",
                "Default": "155.33.133.6/32",
                "Type": "String"
            },
            "IPtoBlock2": {
                "Description": "IPAddress to be blocked",
                "Default": "192.0.7.0/24",
                "Type": "String"
            },
            "ALB":{
                "Description": "LoadBalancer arn for Rule10",
                "Default": "${aws_lb.appLoadbalancer.arn}",
                "Type": "String"
            }
          },
        "Resources": {
        "wafrSQLiSet": {
            "Type": "AWS::WAFRegional::SqlInjectionMatchSet",
            "Properties": {
                "Name": "wafrSQLiSet",
                "SqlInjectionMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "Authorization"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "Authorization"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrSQLiRule": {
            "Type": "AWS::WAFRegional::Rule",
            "DependsOn": [
                "wafrSQLiSet"
            ],
            "Properties": {
                "MetricName": "wafrSQLiRule",
                "Name": "wafr-SQLiRule",
                "Predicates": [
                    {
                        "Type": "SqlInjectionMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrSQLiSet"
                        }
                    }
                ]
            }
        },
          "MyIPSetWhiteList": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": "WhiteList IP Address Set",
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": "155.33.135.11/32"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "192.0.7.0/24"
                    }
                ]
            }
        },
        "MyIPSetWhiteListRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "Name": "WhiteList IP Address Rule",
                "MetricName": "MyIPSetWhiteListRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "MyIPSetWhiteList"
                        },
                        "Negated": false,
                        "Type": "IPMatch"
                    }
                ]
            }
        },
        "myIPSetBlacklist": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": "myIPSetBlacklist",
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": {
                            "Ref": "IPtoBlock1"
                        }
                    },
                    {
                        "Type": "IPV4",
                        "Value": {
                            "Ref": "IPtoBlock2"
                        }
                    }
                ]
            }
        },
        "myIPSetBlacklistRule": {
            "Type": "AWS::WAFRegional::Rule",
            "DependsOn": [
                "myIPSetBlacklist"
            ],
            "Properties": {
                "Name": "Blacklist IP Address Rule",
                "MetricName": "myIPSetBlacklistRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "myIPSetBlacklist"
                        },
                        "Negated": false,
                        "Type": "IPMatch"
                    }
                ]
            }
        },
         "MyScanProbesSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": "MyScanProbesSet"
            }
        },
        "MyScansProbesRule": {
            "Type": "AWS::WAFRegional::Rule",
            "DependsOn": "MyScanProbesSet",
            "Properties": {
                "Name": "MyScansProbesRule",
                "MetricName": "SecurityAutomationsScansProbesRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "MyScanProbesSet"
                        },
                        "Negated": false,
                        "Type": "IPMatch"
                    }
                ]
            }
        },
        "wafrXSSSet": {
            "Type": "AWS::WAFRegional::XssMatchSet",
            "Properties": {
                "Name": "XssMatchSet",
                "XssMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrXSSRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "Name": "wafrXSSRule",
                "MetricName": "wafrXSSRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "wafrXSSSet"
                        },
                        "Negated": false,
                        "Type": "XssMatch"
                    }
                ]
            }
        },
        "sizeRestrict": {
            "Type": "AWS::WAFRegional::SizeConstraintSet",
            "Properties": {
                "Name": "sizeRestrict",
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": "512"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": "1024"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": "204800"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": "4096"
                    }
                ]
            }
        },
        "reqSizeRule": {
            "Type": "AWS::WAFRegional::Rule",
            "DependsOn": [
                "sizeRestrict"
            ],
            "Properties": {
                "MetricName": "reqSizeRule",
                "Name": "reqSizeRule",
                "Predicates": [
                    {
                        "Type": "SizeConstraint",
                        "Negated": false,
                        "DataId": {
                            "Ref": "sizeRestrict"
                        }
                    }
                ]
            }
        },
       "PathStringSetReferers": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": "Path String Referers Set",
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": "../",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": "../",
                        "TextTransformation": "HTML_ENTITY_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TargetString": "../",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TargetString": "../",
                        "TextTransformation": "HTML_ENTITY_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": "://",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": "://",
                        "TextTransformation": "HTML_ENTITY_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TargetString": "://",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TargetString": "://",
                        "TextTransformation": "HTML_ENTITY_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    }
                ]
            }
        },
        "PathStringSetReferersRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "Name": "PathStringSetReferersRule",
                "MetricName": "PathStringSetReferersRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "PathStringSetReferers"
                        },
                        "Negated": false,
                        "Type": "ByteMatch"
                    }
                ]
            }
        },
        "BadReferers": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": "Bad Referers",
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TargetString": "badrefer1",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "authorization"
                        },
                        "TargetString": "QGdtYWlsLmNvbQ==",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "CONTAINS"
                    }
                ]
            }
        },
        "BadReferersRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "Name": "BadReferersRule",
                "MetricName": "BadReferersRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "BadReferers"
                        },
                        "Negated": false,
                        "Type": "ByteMatch"
                    }
                ]
            }
        },
        "wafrCSRFMethodStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": "Server Side Includes Set",
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": "/includes",
                        "TextTransformation": "URL_DECODE",
                        "PositionalConstraint": "STARTS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".cfg",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".conf",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".config",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".ini",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".log",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".bak",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".bakup",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TargetString": ".txt",
                        "TextTransformation": "LOWERCASE",
                        "PositionalConstraint": "ENDS_WITH"
                    }
                ]
            }
        },
        "wafrCSRFRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "Name": "wafrCSRFRule",
                "MetricName": "wafrCSRFRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "wafrCSRFMethodStringSet"
                        },
                        "Negated": false,
                        "Type": "ByteMatch"
                    }
                ]
            }
        },
         "WAFAutoBlockSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": "Auto Block Set"
            }
        },
        "MyAutoBlockRule": {
            "Type": "AWS::WAFRegional::Rule",
            "DependsOn": "WAFAutoBlockSet",
            "Properties": {
                "Name": "Auto Block Rule",
                "MetricName": "AutoBlockRule",
                "Predicates": [
                    {
                        "DataId": {
                            "Ref": "WAFAutoBlockSet"
                        },
                        "Negated": false,
                        "Type": "IPMatch"
                    }
                ]
            }
        },
         "MyWebACL": {
            "Type": "AWS::WAFRegional::WebACL",
            "Properties": {
                "Name": "MyWebACL",
                "DefaultAction": {
                    "Type": "ALLOW"
                },
                "MetricName": "MyWebACL",
                "Rules": [
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 1,
                        "RuleId": {
                            "Ref": "reqSizeRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "ALLOW"
                        },
                        "Priority": 2,
                        "RuleId": {
                            "Ref": "MyIPSetWhiteListRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 3,
                        "RuleId": {
                            "Ref": "myIPSetBlacklistRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 4,
                        "RuleId": {
                            "Ref": "MyAutoBlockRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 5,
                        "RuleId": {
                            "Ref": "wafrSQLiRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 6,
                        "RuleId": {
                            "Ref": "BadReferersRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 7,
                        "RuleId": {
                            "Ref": "PathStringSetReferersRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 8,
                        "RuleId": {
                            "Ref": "wafrCSRFRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 9,
                        "RuleId": {
                            "Ref": "wafrXSSRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 10,
                        "RuleId": {
                            "Ref": "MyScansProbesRule"
                        }
                    }
                ]
            }
        },
        "MyWebACLAssociation": {
            "Type": "AWS::WAFRegional::WebACLAssociation",
            "DependsOn": [
                "MyWebACL"
            ],
            "Properties": {
                "ResourceArn": {
                    "Ref": "ALB"
                },
                "WebACLId": {
                    "Ref": "MyWebACL"
                }
            }
        }
    }
  }
  DEPLOY
  parameters = {
     ALB = "${aws_lb.appLoadbalancer.arn}"
  }
  deployment_mode = "Incremental"
}