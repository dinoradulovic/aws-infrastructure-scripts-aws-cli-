#!/bin/bash

THIS_DIR="$(dirname "$0")"
source $THIS_DIR/_inputs
source $THIS_DIR/_outputs

aws --profile $AWS_PROFILE ec2 delete-security-group --group-id $DB_SECURITY_GROUP_ID
echo "  Security Group '$DB_SECURITY_GROUP_ID' DELETED"
aws --profile $AWS_PROFILE ec2 delete-security-group --group-id $APP_SERVER_SECURITY_GROUP_ID
echo "  Security Group '$APP_SERVER_SECURITY_GROUP_ID' DELETED"
