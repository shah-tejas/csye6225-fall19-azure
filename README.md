# csye6225-fall19-azure

## Team Information

| Name | NEU ID | Email Address |
| --- | --- | --- |
| Ishita Sequeira| 001403357 | sequeira.i@husky.neu.edu |
| Tejas Shah | 001449694 | shah.te@husky.neu.edu |
| Sumit Anglekar | 001475969 | anglekar.s@husky.neu.edu |

## Azure Infrastructure

    - The architecture for the infrastructure is created using Microsoft Azure.
    - Terraform is used to create the Azure Resources.

### Azure Services
    - Azure Virtual Network
    - Azure Blob Storage
    - Azure Virtual Machines
    - Virtual Machine Scale Sets
    - Load Balancer
    - Azure Database for PostgreSQL
    - CosmosDB
    - Azure DNS
    - Event Grid
    - Azure Functions


## Packer
    - Packer is used to create custom Images for Virtual Machines.
    - The custom Image created is registered to the Azure Resource Group passed as a variable for Packer.


## Terraform

### Prerequisites:
To create the infrastructure using Terraform, following resources need to be created manually on Azure Portal:

- Azure Resource Group
- Azure DNS Zone (for your domain)

### Installing Terraform:
    Kindly follow the steps given in the following link:
    https://askubuntu.com/questions/983351/how-to-install-terraform-in-ubuntu

### Initializating script:

    1. terraform init
    - The terraform init command is used to initialize a working directory containing Terraform configuration files. This is the first command that should be run after writing a new Terraform configuration or cloning an existing one from version control. It is safe to run this command multiple times.

### There are 2 scripts:

    1. terraform apply -   This is the script to create a stack to setup AWS network infrastructure.
    2. terraform destroy - This is to terminate the entire network stack.

### File significance:
    1. Building modules for individual instances:
        a. Each module will have a single instance related to an environment and aws region.
        b. For our understanding we have created just modules, namely, module and childmodule. They will have two different individual instances.
    
    2. "main.tf"     - This file has the entire network infrastructure setup with all given resourse components.
    
    3. "variable.tf" - All the initialized variables in main.tf or provider.tf must be defined with appropriate type                      and description in this particular file.
    
    4."terraform.tfvars" - We can pre-define the inputs in the .tfvars file if aren't passing them via command line. 
    This file is optional.
    
    5. Miscellaneous - There are other files and folders like "terraform.tfstate", "terraform.tfstate.backup"                        which maintain the details of passed input parameters and map them in a particular structure. These file are unique to individual modules.

### Instructions to run script:

    1. Clone the repository
    2. Run the packer commands (Refer Packer ReadMe.md)
    2. Now navigate to script folder using command "cd infrastructure/azure/terraform/"
    3. create modules if need or run `terraform init` in each module
    4. run `terraform apply` to input the resource values via command line.
    5. run `terraform destroy` and input all the required paramters  specific to that particular vpc