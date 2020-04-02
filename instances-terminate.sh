#!/bin/bash

THIS_DIR="$(dirname "$0")"
source $THIS_DIR/_inputs
source $THIS_DIR/_outputs

aws --profile $AWS_PROFILE ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null
echo "EC2 Instance ID '$INSTANCE_ID' Terminated"
aws --profile $AWS_PROFILE rds delete-db-instance --db-instance-identifier $DB_INSTANCE_IDENTIFIER --skip-final-snapshot > /dev/null
echo "RDS DB Instance IDENTIFIER '$DB_INSTANCE_IDENTIFIER' Deleted"
