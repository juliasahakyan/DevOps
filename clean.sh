#!/bin/bash

clean_ec2() {
  INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=NewInstance" --query 'Reservations[].Instances[].InstanceId' --output text)
  if [ -z "$INSTANCE_IDS" ]; then
    echo "No instances found with name NewInstance"
    return
  fi

  for INSTANCE_ID in $INSTANCE_IDS; do
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
    if [ $? -eq 0 ]; then
      echo "EC2 instance $INSTANCE_ID successfully terminated"
    else
            echo "Error terminate instance"
    fi
  done
}

clean_subnets() {
  SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=mySubnet*" --query 'Subnets[].SubnetId' --output text)
  for SUBNET_ID in $SUBNET_IDS; do
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID"
    if [ $? -eq 0 ]; then
      echo "Subnet $SUBNET_ID deleted"
        else
                echo "Error deleting subnet"
    fi
  done

    RTB_ID=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=myRTB" --query 'RouteTables[0].RouteTableId' --output text)
  aws ec2 delete-route-table --route-table-id "$RTB_ID"
  if [ $? -eq 0 ]; then
    echo "Route table $RTB_ID deleted"
        else
                echo "Error deleting RTB"
  fi
}
clean_igw() {
  IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=myIGW" --query 'InternetGateways[0].InternetGatewayId' --output text)
VPC_ID=$(aws ec2 describe-internet-gateways --internet-gateway-id "$IGW_ID" --query 'InternetGateways[].Attachments[].VpcId' --output text)

  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID"
  echo "Internet gateway $IGW_ID detached from VPC $VPC_ID"

  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID"
  if [ $? -eq 0 ]; then
    echo "Internet gateway $IGW_ID deleted"
        else
                echo "Error deleting IGW"
  fi
}

clean_sg() {
            SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=my_sg" --query 'SecurityGroups[].GroupId' --output text)
    for DEP_ID in $(aws ec2 describe-network-interfaces --filters "Name=group-id,Values=$SG_ID" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text); do
        aws ec2 detach-network-interface --attachment-id $(aws ec2 describe-network-interfaces --network-interface-id $DEP_ID --query 'NetworkInterfaces[].Attachment.AttachmentId' --output text)
        aws ec2 wait network-interface-available --network-interface-ids $DEP_ID
    done
    aws ec2 delete-security-group --group-id $SG_ID
        if [ $? -eq 0 ]; then
                echo "Security group $SG_ID successfully deleted"
        else
                echo "Error deleting SG"
        fi
clean_vpc() {
  VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=myVPC" --query 'Vpcs[0].VpcId' --output text)
  aws ec2 delete-vpc --vpc-id "$VPC_ID"
  if [ $? -eq 0 ]; then
    echo "VPC $VPC_ID deleted"
        else
                echo "Error deleting VPC"
  fi
}
#Main Script
clean_ec2
clean_subnets
clean_igw
clean_sg
clean_vpc
