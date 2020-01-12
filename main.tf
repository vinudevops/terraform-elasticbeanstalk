#Access to the list of AWS Availability Zones 
data "aws_availability_zones" "availability" {
 
}

#provider is used to interact with the many resources supported by AWS

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}


#create vpc 

resource "aws_vpc" "pn_vpc_main" {
  cidr_block = "${var.pn_cidr}"  
  tags = {
    Name = "pn_vpc"
  }
}

#internet Gateway
resource "aws_internet_gateway" "pn_ig" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
}

#route Table
#public
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.pn_ig.id}"
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "natgateway" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  
  route{
    cidr_block = "0.0.0.0/0"
    nat_gateway_id= "${aws_nat_gateway.nat_gw.id}"
  }
  tags = {
    Name = "natgateway"
  }
}
#private

resource "aws_default_route_table" "private" {
 default_route_table_id = "${aws_vpc.pn_vpc_main.default_route_table_id}"

tags =  {
  Name = "private"
}
}

#subnet

resource "aws_subnet" "pn_pnn_public" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.pn_pnn_public_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.availability.names[0]}" 
  tags =  {
  Name = "pn_pnn_public"
}
}

resource "aws_subnet" "pn_pnn_public2" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.pn_pnn_public2_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${data.aws_availability_zones.availability.names[1]}" 
  tags =  {
  Name = "pn_pnn_public2"
}
}

resource "aws_subnet" "pn_pnn_private" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.pn_pnn_private_cidr}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.availability.names[0]}" 
  tags =  {
  Name = "pn_pnn_private"
}
}

resource "aws_subnet" "pn_pnn_private2" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.pn_pnn_private2_cidr}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.availability.names[1]}" 
  tags =  {
  Name = "pn_pnn_private2"
}
}

resource "aws_subnet" "pn_rds_av1" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.rds1_cidr}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.availability.names[0]}"
tags = {
  name = "pn_rds_av1"
}

}

resource "aws_subnet" "pn_rds_av2" {
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  cidr_block = "${var.rds2_cidr}"
  map_public_ip_on_launch = false
  availability_zone = "${data.aws_availability_zones.availability.names[1]}"
tags = {
  name = "pn_rds_av1"
}


}


# Subnet Associations
resource "aws_route_table_association" "public1_association" {
  subnet_id = "${aws_subnet.pn_pnn_public.id}"
  route_table_id = "${aws_route_table.public.id}"
  
}

resource "aws_route_table_association" "public2_association" {
  subnet_id = "${aws_subnet.pn_pnn_public2.id}"
  route_table_id = "${aws_route_table.public.id}"
  
}

resource "aws_route_table_association" "private1_association_ec2" {
  subnet_id = "${aws_subnet.pn_pnn_private.id}"
  route_table_id = "${aws_route_table.natgateway.id}"
}

resource "aws_route_table_association" "private2_association_ec2" {
  subnet_id = "${aws_subnet.pn_pnn_private2.id}"
  route_table_id = "${aws_route_table.natgateway.id}"
}
resource "aws_route_table_association" "rds1_association" {
  subnet_id = "${aws_subnet.pn_rds_av1.id}"
  route_table_id = "${aws_default_route_table.private.id}"
  
}

resource "aws_route_table_association" "rds2_association" {
  subnet_id = "${aws_subnet.pn_rds_av2.id}"
  route_table_id = "${aws_default_route_table.private.id}"
}

#nat Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.pn_pnn_public.id}"

  tags ={
    Name = "gw_NAT"
  }
}

resource "aws_eip" "nat_eip" {
vpc = true

}

#security group 

resource "aws_security_group" "pn_prod_ec2"{
  vpc_id = "${aws_vpc.pn_vpc_main.id}"
  name = "pn_prod_ec2"
  description = "App prod security group"
  egress {
    from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    Name = "pn_prod_ec2"
  }

}

#keypair

resource "aws_key_pair" "app" {
  key_name = "app-prod" 
  public_key = "${file("${var.SSH_PUBLIC_KEY}")}"
}

#elasticBeanstalk environment creation

resource "aws_elastic_beanstalk_application" "schoolerbot_stage" {
  name= "schoolerbot-stage"
  description = "schoolerbot-stage"
}

resource "aws_elastic_beanstalk_environment" "schoolerbot-stage"{
  name = "app-prod"
  application = "${aws_elastic_beanstalk_application.schoolerbot_stage.name}"
  #solution_stack_name = "64bit Amazon Linux 2018.03 v4.10.2 running Node.js"
  solution_stack_name = "${var.eb_solution_stack_name}"

setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "aws-elasticbeanstalk-service-role"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.pn_vpc_main.id}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name= "Subnets"
    value = "${aws_subnet.pn_pnn_private.id},${aws_subnet.pn_pnn_private2.id}"
  } 

setting {
  namespace = "aws:ec2:vpc"
  name = "ELBSubnets"
  value = "${aws_subnet.pn_pnn_public.id},${aws_subnet.pn_pnn_public2.id}"

}

#load balancer
setting {
  namespace = "aws:elasticbeanstalk:environment"
  name = "LoadBalancerType"
  value = "application"

}

#rds instance
 setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "false"
  }

setting {
  namespace = "aws:rds:dbinstance"
  name = "InstanceType"
  value = "t2.micro"
}

setting {
  namespace = "aws:rds:dbinstance"
  name = "DBAllocatedStorage"
  value = 20
}

setting {
  namespace = "aws:ec2:vpc"
    name = "DBSubnets"
    value = "${aws_subnet.pn_rds_av2.id}, ${aws_subnet.pn_rds_av1.id}"
    
}

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "app-ec2-role"
  } 

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.pn_prod_ec2.id}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "${aws_key_pair.app.id}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.micro"
  }
}
