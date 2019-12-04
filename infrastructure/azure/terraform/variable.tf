# Azure Region
variable "region" {
  type = "string"
  default = "East US"
  description = "Azure Region to create the infrastructure in"
}

# Virtual Network address space
variable "network_address" {
  type = "string"
  default = "10.0.0.0/16"
  description = "Address space to allocate for the Virtual Network"
}

# Subnet address prefix
variable "subnet_addresses" {
  type = "list"
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  description = "Adress prefixes for the subnets"
}

# SSH public key
variable "ssh_public_key" {
  type = "string"
  description = "SSH Public key to ssh into the VM"
}

# DB username
variable "db_username" {
  type = "string"
  default = "dbadmin"
  description = "The username for the database"
}

# DB username
variable "db_password" {
  type = "string"
  default = "Cloud!23"
  description = "The password for the database"
}
