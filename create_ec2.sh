#!/bin/bash

create_sec_group() {
    if aws ec2 describe-security-groups --filters Name=group-name,Values=my_sg | grep -q my_sg; then
        echo "Security group my_sg already exists"
        SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=my_sg --query SecurityGroups[*].GroupId --output text)
    else
        SG_ID=$(aws ec2 create-security-group --group-name my_sg --description "My security group" --vpc-id "${VPC_ID}" --output text)
    fi
    if ! aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[*].{IP:IpPermissions}" | grep -q "tcp\|22\|0.0.0.0/0"; then
        aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
        echo "Added rules to Security Group"
    else
        echo "Security group my_sg already has rules for port 22"
    fi
}

create_ec2() {
local KEY="$1"
local SUBNET_ID="$2"
local SG_ID="$3"
local INSTANCE_NAME="$4"

# Create the EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0557a15b87f6559cf  --instance-type t2.micro  --key-name "${KEY}" --security-group-ids "${SG_ID}" --subnet-id "${SUBNET_ID}" --output text --query 'Instances[*].InstanceId')

# Check if the instance was created successfully
if [ -z "${INSTANCE_ID}" ]; then
    echo "Error creating EC2 instance."
    exit 1
fi

# Add a name tag to the instance
aws ec2 create-tags --resources "${INSTANCE_ID}" --tags Key=Name,Value="${INSTANCE_NAME}"

# Check if the name tag was added successfully
if [ $? -ne 0 ]; then
    echo "Error adding name tag to EC2 instance."
    exit 1
fi
}
create_sec_group
create_ec2 "Newkeypair" "$SUBNET_ID3" "$SG_ID" "NewInstance"
echo "Instance Created"
