#!/bin/bash

THIS_DIR="$(dirname "$0")"
OUTPUTS="$THIS_DIR/_outputs"
source $THIS_DIR/_inputs

# ########################################################
#  VPC CREATION 
# ########################################################

# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws --profile $AWS_PROFILE ec2 create-vpc \
--output text \
--cidr-block $VPC_CIDR \
--query 'Vpc.VpcId')
echo "  VPC ID '$VPC_ID' CREATED."
echo "VPC_ID="\"$VPC_ID\" > $OUTPUTS

# Add Name tag to VPC
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $VPC_ID \
  --tags "Key=Name,Value=$VPC_NAME"
echo "  VPC ID '$VPC_ID' NAMED as '$VPC_NAME'."

# Enable DNS Hostnames
aws --profile $AWS_PROFILE ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames "{\"Value\":true}"
echo "  Enabled DNS hostnames for VPC ID '$VPC_ID'"

# Create Internet gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws --profile $AWS_PROFILE ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' \
  --output text \
  --region $AWS_REGION)
echo "  Internet Gateway ID '$IGW_ID' CREATED."

# Attach Internet gateway to your VPC
aws --profile $AWS_PROFILE ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID \
  --region $AWS_REGION
echo "  Internet Gateway ID '$IGW_ID' ATTACHED to VPC ID '$VPC_ID'."
echo "IGW_ID="\"$IGW_ID\" >> $OUTPUTS


# ########################################################
# PUBLIC SUBNET CREATION
# ########################################################

# Create Public Subnet
echo "Creating Public Subnet..."
PUBLIC_SUBNET_ID=$(aws --profile $AWS_PROFILE ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR \
  --availability-zone $PUBLIC_SUBNET_AZ \
  --query 'Subnet.SubnetId' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$PUBLIC_SUBNET_ID' CREATED in '$PUBLIC_SUBNET_AZ'" \
  "Availability Zone."
echo "PUBLIC_SUBNET_ID="\"$PUBLIC_SUBNET_ID\" >> $OUTPUTS

# Add Name tag to Public Subnet
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $PUBLIC_SUBNET_ID \
  --tags "Key=Name,Value=$PUBLIC_SUBNET_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$PUBLIC_SUBNET_ID' NAMED as" \
  "'$PUBLIC_SUBNET_NAME'."

# Enable Auto-assign Public IP on Public Subnet
aws ec2 --profile $AWS_PROFILE modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_ID \
  --map-public-ip-on-launch \
  --region $AWS_REGION
echo "  'Auto-assign Public IP' ENABLED on Public Subnet ID" \
  "'$PUBLIC_SUBNET_ID'."


########################################################
# ROUTE TABLE FOR PUBLIC SUBNET CREATION
########################################################

# Create Route Table
echo "Creating Route Table..."
PUBLIC_SUBNET_ROUTE_TABLE_ID=$(aws ec2 --profile $AWS_PROFILE create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region $AWS_REGION)
echo "  Route Table ID '$PUBLIC_SUBNET_ROUTE_TABLE_ID' CREATED."


# Add Name tag to Route Table
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $PUBLIC_SUBNET_ROUTE_TABLE_ID \
  --tags "Key=Name,Value=$PUBLIC_SUBNET_ROUTE_TABLE_NAME" \
  --region $AWS_REGION
echo "  Route Table ID '$PUBLIC_SUBNET_ROUTE_TABLE_ID' NAMED as" \
  "'$PUBLIC_SUBNET_ROUTE_TABLE_NAME'."


# Add route to Internet Gateway
aws ec2 --profile $AWS_PROFILE create-route \
  --route-table-id $PUBLIC_SUBNET_ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID \
  --region $AWS_REGION > /dev/null
echo "  Route to '0.0.0.0/0' via Internet Gateway ID '$IGW_ID' ADDED to" \
  "Route Table ID '$PUBLIC_SUBNET_ROUTE_TABLE_ID'."
echo "PUBLIC_SUBNET_ROUTE_TABLE_ID="\"$PUBLIC_SUBNET_ROUTE_TABLE_ID\" >> $OUTPUTS

# Associate Public Subnet with Route Table
PUBLIC_SUBNET_ROUTE_ASSOCIATION_ID=$(aws ec2 --profile $AWS_PROFILE associate-route-table \
  --subnet-id $PUBLIC_SUBNET_ID \
  --route-table-id $PUBLIC_SUBNET_ROUTE_TABLE_ID \
  --query 'AssociationId' \
  --output text \
  --region $AWS_REGION)
echo "  Public Subnet ID '$PUBLIC_SUBNET_ID' ASSOCIATED with Route Table ID" \
  "'$PUBLIC_SUBNET_ROUTE_TABLE_ID'."
echo "PUBLIC_SUBNET_ROUTE_ASSOCIATION_ID="\"$PUBLIC_SUBNET_ROUTE_ASSOCIATION_ID\" >> $OUTPUTS


########################################################
# PRIVATE SUBNETS CREATION
########################################################
echo "Creating Two Private Subnets for DB..."

# Create First Private Subnet
PRIVATE_SUBNET_1_ID=$(aws --profile $AWS_PROFILE ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_1_CIDR \
  --availability-zone $PRIVATE_SUBNET_1_AZ \
  --query 'Subnet.SubnetId' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$PRIVATE_SUBNET_1_ID' CREATED in '$PRIVATE_SUBNET_1_AZ'" \
  "Availability Zone."
echo "PRIVATE_SUBNET_1_ID="\"$PRIVATE_SUBNET_1_ID\" >> $OUTPUTS

# Add Name tag to First Private Subnet
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $PRIVATE_SUBNET_1_ID \
  --tags "Key=Name,Value=$PRIVATE_SUBNET_1_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$PRIVATE_SUBNET_1_ID' NAMED as" \
  "'$PRIVATE_SUBNET_1_NAME'."

# Create Second Private Subnet
PRIVATE_SUBNET_2_ID=$(aws --profile $AWS_PROFILE ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_SUBNET_2_CIDR \
  --availability-zone $PRIVATE_SUBNET_2_AZ \
  --query 'Subnet.SubnetId' \
  --output text \
  --region $AWS_REGION)
echo "  Subnet ID '$PRIVATE_SUBNET_2_ID' CREATED in '$PRIVATE_SUBNET_2_AZ'" \
  "Availability Zone."
echo "PRIVATE_SUBNET_2_ID="\"$PRIVATE_SUBNET_2_ID\" >> $OUTPUTS

# Add Name tag to Second Private Subnet
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $PRIVATE_SUBNET_2_ID \
  --tags "Key=Name,Value=$PRIVATE_SUBNET_2_NAME" \
  --region $AWS_REGION
echo "  Subnet ID '$PRIVATE_SUBNET_2_ID' NAMED as" \
  "'$PRIVATE_SUBNET_2_NAME'."


########################################################
# ROUTE TABLE FOR PRIVATE SUBENTS CREATION
########################################################

# Create Route Table
echo "Creating Route Table..."
PRIVATE_SUBNETS_ROUTE_TABLE_ID=$(aws ec2 --profile $AWS_PROFILE create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' \
  --output text \
  --region $AWS_REGION)
echo "  Route Table ID '$PRIVATE_SUBNETS_ROUTE_TABLE_ID' CREATED."
echo "PRIVATE_SUBNETS_ROUTE_TABLE_ID="\"$PRIVATE_SUBNETS_ROUTE_TABLE_ID\" >> $OUTPUTS

# Add Name tag to Route Table
aws --profile $AWS_PROFILE ec2 create-tags \
  --resources $PRIVATE_SUBNETS_ROUTE_TABLE_ID \
  --tags "Key=Name,Value=$PRIVATE_SUBNETS_ROUTE_TABLE_NAME" \
  --region $AWS_REGION
echo "  Route Table ID '$PRIVATE_SUBNETS_ROUTE_TABLE_ID' NAMED as" \
  "'$PRIVATE_SUBNETS_ROUTE_TABLE_NAME'."

# Associate First Private Subnet with Route Table
PRIVATE_SUBNET_1_ROUTE_ASSOCIATION_ID=$(aws ec2 --profile $AWS_PROFILE associate-route-table \
  --subnet-id $PRIVATE_SUBNET_1_ID \
  --route-table-id $PRIVATE_SUBNETS_ROUTE_TABLE_ID \
  --query 'AssociationId' \
  --output text \
  --region $AWS_REGION)
echo "  Public Subnet ID '$PRIVATE_SUBNET_1_ID' ASSOCIATED with Route Table ID" \
  "'$PRIVATE_SUBNETS_ROUTE_TABLE_ID'."
echo "PRIVATE_SUBNET_1_ROUTE_ASSOCIATION_ID="\"$PRIVATE_SUBNET_1_ROUTE_ASSOCIATION_ID\" >> $OUTPUTS

# Associate Second Private Subnet with Route Table
PRIVATE_SUBNET_2_ROUTE_ASSOCIATION_ID=$(aws ec2 --profile $AWS_PROFILE associate-route-table \
  --subnet-id $PRIVATE_SUBNET_2_ID \
  --route-table-id $PRIVATE_SUBNETS_ROUTE_TABLE_ID \
  --query 'AssociationId' \
  --output text \
  --region $AWS_REGION)
echo "  Public Subnet ID '$PRIVATE_SUBNET_2_ID' ASSOCIATED with Route Table ID" \
  "'$PRIVATE_SUBNETS_ROUTE_TABLE_ID'."
echo "PRIVATE_SUBNET_2_ROUTE_ASSOCIATION_ID="\"$PRIVATE_SUBNET_2_ROUTE_ASSOCIATION_ID\" >> $OUTPUTS


########################################################
# SUBNET GROUP CREATION
########################################################
echo "Creating Subnet Group for DB instance..."
aws rds --profile $AWS_PROFILE create-db-subnet-group \
--db-subnet-group-name $DB_SUBNET_GROUP_NAME \
--db-subnet-group-description "DB Subnet Group Description" \
--subnet-ids $PRIVATE_SUBNET_1_ID $PRIVATE_SUBNET_2_ID > /dev/null

echo "  Subnet Group NAME db-subnet-group CREATED."
echo "DB_SUBNET_GROUP_NAME="\"$DB_SUBNET_GROUP_NAME\" >> $OUTPUTS
