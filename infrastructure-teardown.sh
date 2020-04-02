#!/bin/bash

THIS_DIR="$(dirname "$0")"
source $THIS_DIR/_inputs
source $THIS_DIR/_outputs

aws --profile $AWS_PROFILE rds delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP_NAME
echo "  Subnet Group '$DB_SUBNET_GROUP_NAME' DELETED"

aws --profile $AWS_PROFILE ec2 disassociate-route-table --association-id $PRIVATE_SUBNET_1_ROUTE_ASSOCIATION_ID
aws --profile $AWS_PROFILE ec2 disassociate-route-table --association-id $PRIVATE_SUBNET_2_ROUTE_ASSOCIATION_ID
aws --profile $AWS_PROFILE ec2 delete-route-table --route-table-id $PRIVATE_SUBNETS_ROUTE_TABLE_ID
echo "  Route Table '$PRIVATE_SUBNETS_ROUTE_TABLE_ID' DELETED"

aws --profile $AWS_PROFILE ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_1_ID
echo "  SUBNET  '$PRIVATE_SUBNET_1_ID' DELETED"
aws --profile $AWS_PROFILE ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_2_ID
echo "  SUBNET  '$PRIVATE_SUBNET_2_ID' DELETED"

aws --profile $AWS_PROFILE ec2 disassociate-route-table --association-id $PUBLIC_SUBNET_ROUTE_ASSOCIATION_ID
aws --profile $AWS_PROFILE ec2 delete-route-table --route-table-id $PUBLIC_SUBNET_ROUTE_TABLE_ID
echo "  Route Table '$PUBLIC_SUBNET_ROUTE_TABLE_ID' DELETED"

aws --profile $AWS_PROFILE ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws --profile $AWS_PROFILE ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
echo "  IGW '$IGW_ID' DELETED"

aws --profile $AWS_PROFILE ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
echo "  SUBNET  '$PUBLIC_SUBNET_ID' DELETED"

aws --profile $AWS_PROFILE ec2 delete-vpc --vpc-id $VPC_ID
echo "  VPC '$VPC_ID' DELETED"
