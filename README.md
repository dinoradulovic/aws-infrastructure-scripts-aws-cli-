# AWS Backend APIs Infrastructure Scripts (AWS CLI)

This repo contains a collection of scripts to create the network infrastructure on AWS for deploying Backend APIs.

It creates a ***VPC*** with ***Public Subnet*** and ***two Private Subnets***. 

![aws architecture](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/aws-architecture.png)

EC2 Instance is created inside the Public Subnet for the App Server to be deployed into. 
> It also runs the User data shell script that installs Node, PM2, Nginx and configures Nginx as a Reverse Proxy to pass the requests from port :80 to port :3000 where the App Server will be run.

RDS Instance is created inside the Private Subnets for the DB to be created inside.
RDS instance is accessible only from the EC2 instance, which you can use as Bastion Host to connect to DB. 

# Table of Contents 
* [Requirements](#requirements)
* [Configuration](#configuration)
* [Usage](#usage) 
	* [Creating Infrastructure](#creating-infrastructure ) 
	* [Reverting Infrastructure](#reverting-infrastructure) 

# Requirements

These scripts assume you are working in a `Unix based environment` and that you have `AWS CLI v1` (tested with 1.16.68) configured with the named profile. 

<https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html>
<https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html>

# Configuration

Set the required environment variables in ***_inputs*** file. 
```
AWS_PROFILE="aws-user-profile"
AWS_REGION="ap-southeast-1"
VPC_NAME="my-cool-vpc"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.0.0/24"
PUBLIC_SUBNET_AZ="ap-southeast-1a"
PUBLIC_SUBNET_NAME="public-subnet"
PUBLIC_SUBNET_ROUTE_TABLE_NAME="public-route-table"
PRIVATE_SUBNET_1_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_1_AZ="ap-southeast-1a"
PRIVATE_SUBNET_1_NAME="private-subnet-1"
PRIVATE_SUBNET_2_CIDR="10.0.2.0/24"
PRIVATE_SUBNET_2_AZ="ap-southeast-1b"
PRIVATE_SUBNET_2_NAME="private-subnet-2"
PRIVATE_SUBNETS_ROUTE_TABLE_NAME="private-route-table"
DB_SUBNET_GROUP_NAME="db-subnet-group"
KEY_PAIR_NAME="key-pair-name"
AMI_IMAGE_ID="ami-048a01c78f7bae4aa"
APP_SERVER_SECURITY_GROUP_NAME="app-server-security-group"
DATABASE_SECURITY_GROUP_NAME="db-security-group"
DB_INSTANCE_IDENTIFIER="my-cool-db-instance"
DB_MASTER_USERNAME="postgres"
DB_MASTER_PASSWORD="secret99"
```
> NOTE: _inputs and _outputs files are committed as an examples. If you use these scripts in your projects, don't commit these files. 

# Usage

Run the scripts in the exact order. 

## Creating Infrastructure

### ./infrastructure-create.sh 

This script creates VPC with Public Subnet and Two Private Subnets.

Make sure you place the private subnets in ***two different availability zones*** ([RDS requirement](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_VPC.WorkingWithRDSInstanceinaVPC.html#Overview.RDSVPC.Create)). 

#### Steps: 
1. **VPC**
   - Creates VPC
   - Adds Name tag
   - Enables DNS Hostnames
   - Creates Internet Gateway
   - Attaches Internet gateway to VPC  
2. **Public Subnet**
   - Creates Public Subnet
   - Adds Name Tag
   - Enables auto-assign public IP
3. **Public Subnet Route Table**
   - Creates Route table
   - Adds Name Tag
   - Add route to Internet Gateway (this is what makes the subnet public)
   - Associate Public Subnet with Route Table
4. **Private Subnets**
   - Creates First Private Subnet
   - Adds Name Tag
   - Creates Second Private Subnet
   - Adds Name Tag 
5. **Private Subnets Route Table**
   - Creates Route Table
   - Adds Name Tag
   - Associates Private Subnets with Route Table
6. **Subnet Group**
   - Creates Subnet Group with Two Private Subnets

![infractructure create preview](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/infrastructure-create.png)

### ./instances-create.sh 

This script creates the EC2 instance and RDS instance inside previously created network infrastructure.

It also creates two security groups and adds inbound rules to them.

First security group is assigned to EC2 instance where the App Server will be deployed. It opens up a port 80 for everyone and port 22 for your local IP address.  

Second security group is assigned to RDS instance where the Database is created. It opens up port 5432 (PostgreSQL) for EC2 instance only. App Server can access the data from the database and this EC2 instance also serves as a bastion host.

![instances create preview](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/instances-create.png)

## Reverting Infrastructure

In order to delete all previously created AWS resources, you need to run these scripts in order. 
These scripts use the parameters saved into _outputs file (filled in by the creational scripts) and deletes all the resources. 

### ./instances-delete.sh 
This script will terminate/delete EC2 instance and RDS instance.  

Before proceeding to the next script, wait until the RDS instance is fully deleted (you can check in the console), because it won't let you delete the security group associated with RDS instance while deletion is in progress.

![instances terminate preview](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/instances-terminate.png)

### ./security-groups-delete.sh 

Deletes two security groups associated with the EC2 and RDS instance. 

![security groups delete preview](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/security-groups-delete.png)

### ./infrastructure-teardown.sh 
Deletes the rest of the infrastructure.

![infrastructure teardown preview](https://github.com/dinoradulovic/infrastructure-scripts-aws-cli/blob/media/infrastructure-teardown.png)
