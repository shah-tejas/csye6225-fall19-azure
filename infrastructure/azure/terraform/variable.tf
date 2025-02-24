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

variable "alert_email" {
  type = "string"
  default = "shah.te@husky.neu.edu"
  description = "email address to send alerts"
}

variable "hosted_zone_name" {
  type = "string"
  description = "Unique hosted zone name for postgress and cosmos db"
}

variable "domain_name" {
  type = "string"
  description = "Domain name for the hosted zone"
}

variable "resource_group_name" {
  type = "string"
  default = "ccwebapp_infrastructure"
  description = "Resource group name"
}

variable "functionapp" {
  type = "string"
  default = "./function.zip"
}