#!/bin/bash
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
echo "VPC ${VPC_ID} created!!"
SUBNET_ID0=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
echo "Subnet 1 ${SUBNET_ID0} created"
SUBNET_ID1=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
echo "Subnet 2 ${SUBNET_ID1} created"
SUBNET_ID2=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
echo "Subnet 3 ${SUBNET_ID2} created"
SUBNET_ID3=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.0.3.0/24 --availability-zone us-east-1a --query Subnet.SubnetId --output text)
echo "Public ${SUBNET_ID3} created"

# Add name tag to VPC
region="us-east-1"
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=myVPC --region $region

# Create Internet Gateway and retrieve ID
igw_id=$(aws ec2 create-internet-gateway --region $region --query 'InternetGateway.InternetGatewayId' --output text)
echo "Internet Gateway ${igw_id} created"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $igw_id --vpc-id ${VPC_ID} --region $region
echo "IGW attached to VPC"

# Create default route table
RTB_ID=$(aws ec2 create-route-table --vpc-id "${VPC_ID}" --query RouteTable.RouteTableId --output text)
echo "Route Table ${RTB_ID} created"

# Create default route to IGW
aws ec2 create-route --route-table-id "${RTB_ID}" --destination-cidr-block 0.0.0.0/0 --gateway-id "${igw_id}"
echo "Some route in the RTB created!"

# Associate subnet with route table
aws ec2 associate-route-table --route-table-id "${RTB_ID}" --subnet-id "${SUBNET_ID3}"
echo "Associated the route table with the public subnet"

# Add name tag to Internet Gateway
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=myIGW --region $region
echo "VPC, subnet, and Internet Gateway created successfully!"

# Set key pair name
key_name="myKeyPair"

# Create key pair and retrieve private key
aws ec2 create-key-pair --key-name $key_name --region $region --query 'KeyMaterial' --output text > $key_name.ppk

# Set file permissions on private key
chmod 400 $key_name.ppk
echo "Key pair created successfully!"

#crate security group
#Set the Security Group name and description
GROUP_NAME="my-security-group"
GROUP_DESC="My security group description"

# Create the Security Group and retrieve its ID
SG_ID=$(aws ec2 create-security-group --group-name "$GROUP_NAME" --description "$GROUP_DESC" --vpc-id "${VPC_ID}" --output text)
echo "Security Group ${SG_ID} created"

# Add rules to the Security Group
aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
--protocol tcp --port 22 --cidr 0.0.0.0/0 --output text

aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
--protocol tcp --port 80 --cidr 0.0.0.0/0 --output text
echo "Added rules to Security Group with ID: ${SG_ID}"

AMI="ami-0557a15b87f6559cf"  # Amazon Linux 2 AMI ID
INSTANCE_TYPE="t2.micro"     # EC2 instance type
KEY_NAME=$key_name       # Name of your key pair
SECURITY_GROUP_ID=${SG_ID} # ID of the security group to attach
SUBNET_ID="${SUBNET_ID0}"  # ID of the subnet to launch the instance in
INSTANCE_NAME="NewTest"
aws ec2 run-instances --image-id $AMI --count 1 --instance-type $INSTANCE_TYPE \
--key-name $KEY_NAME --security-group-ids ${SG_ID} \
--instance-name $INSTANCE_NAME \
--subnet-id $SUBNET_ID --associate-public-ip-address --output json
echo "new instance crated"

INSTANCE_ID=$(aws ec2 describe-instances --query "sort_by(Reservations[].Instances[], &LaunchTime)[-1].InstanceId" --output text)
aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}"
echo "Instance ${INSTANCE_ID} terminated"
aws ec2 wait instance-terminated --instance-ids "${INSTANCE_ID}"
echo "Instance ${INSTANCE_ID} terminated successfully"

aws ec2 delete-subnet --subnet-id "${SUBNET_ID0}"
echo "Subnet ${SUBNET_ID0} deleted"

aws ec2 delete-subnet --subnet-id "${SUBNET_ID1}"
echo "Subnet ${SUBNET_ID1} deleted"

aws ec2 delete-subnet --subnet-id "${SUBNET_ID2}"
echo "Subnet ${SUBNET_ID2} deleted"

aws ec2 delete-subnet --subnet-id "${SUBNET_ID3}"
echo "Subnet ${SUBNET_ID3} deleted"

aws ec2 delete-route-table --route-table-id "${RTB_ID}"
echo "Route table ${RTB_ID} deleted"

aws ec2 detach-internet-gateway --internet-gateway-id "${igw_id}" --vpc-id "${VPC_ID}"
echo "Internet gateway ${IGW_ID} detached from VPC ${VPC_ID}"
aws ec2 delete-internet-gateway --internet-gateway-id "${igw_id}"
echo "Internet gateway ${IGW_ID} deleted"
aws ec2 delete-key-pair --key-name my-key-pair
echo "Key pair ${key_pair} deleted"
aws ec2 delete-security-group --group-id "${SG_ID}"
echo "Security Group "${SG_ID}" deleted"
aws ec2 delete-vpc --vpc-id "${VPC_ID}"
echo "VPC ${VPC_ID} deleted"





