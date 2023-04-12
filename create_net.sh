#!/bin/bash

create_vpc() {
    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
    if [ $? -ne 0 ]
  then
      echo "Error creating VPC."
      return 1
  fi
  echo $VPC_ID

# Add name tag to VPC
  aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=myVPC
  if [ $? -ne 0 ]
  then
      echo "Error adding name tag to VPC."
      return 1
  fi
}

create_subnet() {
    local VPC_ID="$1"
    local CIDR="$2"
    local AZ="$3"
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block "${CIDR}" --availability-zone "${AZ}" --query Subnet.SubnetId --output text)

if [[ -z $SUBNET_ID ]]; then
        echo "Error creating subnet!"
        exit 1
    fi
    echo $SUBNET_ID

    aws ec2 create-tags --resources "${SUBNET_ID}" --tags Key=Name,Value=mySubnet
    if [ $? -ne 0 ]
    then
        echo "Error adding name tag to subnet."
        return 1
    fi
}

public_ip() {
aws ec2 modify-subnet-attribute --subnet-id "${SUBNET_ID3}" --map-public-ip-on-launch
echo "Auto-assign public IP addresses enabled for subnet ${SUBNET_ID3}!"
}

create_igw() {
    IGW_ID=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
     if [[ -z $IGW_ID ]]; then
        echo "Error creating Internet Gateway!"
        exit 1
    fi
    echo $IGW_ID

    aws ec2 create-tags --resources "${IGW_ID}" --tags Key=Name,Value=myIGW
      if [ $? -ne 0 ]
      then
          echo "Error adding name tag to Interet Gateway."
          return 1
      fi

}

attach_igw() {
    local VPC_ID="$1"
    local IGW_ID="$2"
    aws ec2 attach-internet-gateway --vpc-id "${VPC_ID}" --internet-gateway-id "${IGW_ID}"
    echo "IGW attached to VPC!!"
}

create_route_table() {
    local VPC_ID="$1"
    RTB_ID=$(aws ec2 create-route-table --vpc-id "${VPC_ID}" --query RouteTable.RouteTableId --output text)
    if [[ -z $RTB_ID ]]; then
        echo "Error creating route table!"
        exit 1
    fi
    echo $RTB_ID
    aws ec2 create-tags --resources "${RTB_ID}" --tags Key=Name,Value=myRTB
        if [ $? -ne 0 ]
        then
echo "Error adding name tag to RTB"
            return 1
        fi

}

create_route() {
    local RTB_ID="$1"
    local IGW_ID="$2"
    aws ec2 create-route --route-table-id "${RTB_ID}" --destination-cidr-block 0.0.0.0/0 --gateway-id "${IGW_ID}"
    echo "Some route in the RTB created!"
}

associate_route_table() {
    local RTB_ID="$1"
    local SUBNET_ID="$2"
    aws ec2 associate-route-table --route-table-id "${RTB_ID}" --subnet-id "${SUBNET_ID}"
    echo "Associated the route table with the public subnet!!"
}


# Main script
VPC_ID=$(create_vpc)
echo "VPC ${VPC_ID} created!!"
SUBNET_ID0=$(create_subnet "${VPC_ID}" "10.0.0.0/24" "us-east-1a")
echo "Subnet ${SUBNET_ID0} created!!"
SUBNET_ID1=$(create_subnet "${VPC_ID}" "10.0.1.0/24" "us-east-1a")
echo "Subnet ${SUBNET_ID1} created!!"
SUBNET_ID2=$(create_subnet "${VPC_ID}" "10.0.2.0/24" "us-east-1a")
echo "Subnet ${SUBNET_ID2} created!!"
SUBNET_ID3=$(create_subnet "${VPC_ID}" "10.0.3.0/24" "us-east-1a")
echo "Subnet ${SUBNET_ID3} created!!"
public_ip
IGW_ID=$(create_igw)
echo "Internet Gateway ${IGW_ID} created!!"
attach_igw "${VPC_ID}" "${IGW_ID}"

RTB_ID=$(create_route_table "${VPC_ID}")
echo "Route Table ${RTB_ID} created!"

create_route "${RTB_ID}" "${IGW_ID}"
associate_route_table "${RTB_ID}" "${SUBNET_ID3}"



                    
