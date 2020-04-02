#!/bin/bash

THIS_DIR="$(dirname "$0")"
OUTPUTS="$THIS_DIR/_outputs"
source $THIS_DIR/_inputs
source $OUTPUTS

########################################################
# SECURITY GROUP FOR APP SERVER CREATION
########################################################

# Create Security Group
echo "Creating Security Group for EC2 Instance in Public Subnet..."
APP_SERVER_SECURITY_GROUP_ID=$(aws --profile $AWS_PROFILE ec2 create-security-group \
--group-name $APP_SERVER_SECURITY_GROUP_NAME \
--description "Security group for the App Server instance" \
--vpc-id $VPC_ID \
--output text \
--query 'GroupId')
echo "  Security Group ID '$APP_SERVER_SECURITY_GROUP_ID' CREATED."
echo "APP_SERVER_SECURITY_GROUP_ID="\"$APP_SERVER_SECURITY_GROUP_ID\" >> $OUTPUTS

# Get My IP Address
MY_PUBLIC_IP=$(curl -s https://checkip.amazonaws.com/)

# Authorize Inbound traffic on TCP port 22 (SSH) for my IP
aws ec2 --profile $AWS_PROFILE \
authorize-security-group-ingress --group-id $APP_SERVER_SECURITY_GROUP_ID \
--protocol tcp --port 22 --cidr "$MY_PUBLIC_IP/32"
echo "  Authorized Inbound traffic on TCP port 22 (SSH) for your IP address: '$MY_PUBLIC_IP'."

# Authorize Inbound traffic on TCP port 80 (HTTP) for Everyone
aws ec2 --profile $AWS_PROFILE \
authorize-security-group-ingress --group-id $APP_SERVER_SECURITY_GROUP_ID \
--protocol tcp --port 80 --cidr "0.0.0.0/0"
echo "  Authorized Inbound traffic on TCP port 80 (HTTP) for everyone."


########################################################
# CREATE APP SERVER EC2 INSTANCE
########################################################

echo "Creating App Server EC2 Instance..."
read -r APP_SERVER_PRIVATE_IP_ADDRESS INSTANCE_ID <<< $(aws --profile $AWS_PROFILE \
ec2 run-instances \
--image-id $AMI_IMAGE_ID \
--count 1 \
--instance-type t2.micro \
--key-name $KEY_PAIR_NAME \
--security-group-ids $APP_SERVER_SECURITY_GROUP_ID \
--subnet-id $PUBLIC_SUBNET_ID \
--query 'Instances[0].[PrivateIpAddress, InstanceId]' \
--output text \
--user-data file://$THIS_DIR/user-data.txt)

echo "  EC2 Instance ID '$INSTANCE_ID' CREATED with private ip: $APP_SERVER_PRIVATE_IP_ADDRESS."
echo "INSTANCE_ID="\"$INSTANCE_ID\" >> $OUTPUTS
echo "APP_SERVER_PRIVATE_IP_ADDRESS="\"$APP_SERVER_PRIVATE_IP_ADDRESS\" >> $OUTPUTS


# ########################################################
# # SECURITY GROUP FOR DATABASE CREATION
# ########################################################

# Create Security Group
echo "Creating Security Group for RDS Instance in Private Subnet..."
DB_SECURITY_GROUP_ID=$(aws --profile $AWS_PROFILE ec2 create-security-group \
--group-name $DATABASE_SECURITY_GROUP_NAME \
--description "Security group for the database instance" \
--vpc-id $VPC_ID \
--output text \
--query 'GroupId')
echo "  Security Group ID '$DB_SECURITY_GROUP_ID' CREATED."
echo "DB_SECURITY_GROUP_ID="\"$DB_SECURITY_GROUP_ID\" >> $OUTPUTS

# Authorize Inbound traffic on TCP port 5432 (PostgreSQL) for the EC2 instance (App Server)
aws ec2 --profile $AWS_PROFILE \
authorize-security-group-ingress --group-id $DB_SECURITY_GROUP_ID \
--protocol tcp --port 5432 --cidr $APP_SERVER_PRIVATE_IP_ADDRESS/32
echo "  Authorized Inbound traffic on TCP port 5432 (PostgreSQL) for App Server private IP address: $APP_SERVER_PRIVATE_IP_ADDRESS/32."


########################################################
# CREATE DATABASE RDS INSTANCE
########################################################

echo "Creating Database RDS Instance..."
aws --profile $AWS_PROFILE \
rds create-db-instance \
--no-publicly-accessible \
--allocated-storage "20" \
--db-instance-class "db.t3.micro" \
--db-instance-identifier $DB_INSTANCE_IDENTIFIER \
--engine "postgres" \
--master-username $DB_MASTER_USERNAME \
--master-user-password $DB_MASTER_PASSWORD \
--vpc-security-group-ids $DB_SECURITY_GROUP_ID \
--db-subnet-group-name $DB_SUBNET_GROUP_NAME > /dev/null
echo "  Database RDS DATABASE IDENTIFIER '$DB_INSTANCE_IDENTIFIER' CREATED. $DB_SECURITY_GROUP_ID"
