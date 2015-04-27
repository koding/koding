package terraformer

// SampleTF holds a sample terraform file
var SampleTF = `
// Provider specific configs

provider "aws" {
    access_key = "AKIAJTDKW5IFUUIWVNAA"
    secret_key = "BKULK7pWB2crKtBafYnfcPhh7Ak+iR/ChPfkvrLC"
    region = "sa-east-1"
}


// Template variables

//
// AWS General Config
//

//variable "key_name" {
//    description = "Name of the SSH keypair to use in AWS."
//}

// set the region which is close to you
variable "aws_region" {
    description = "Region name in which resources will be created"
    default     = "sa-east-1"
}

// set secret key
variable "aws_secret_key" {
    description = "AWS Secret key"
    default     = "BKULK7pWB2crKtBafYnfcPhh7Ak+iR/ChPfkvrLC"
}

// set access key
variable "aws_access_key" {
    description = "AWS Access key"
    default     = "AKIAJTDKW5IFUUIWVNAA"
}

//
// VPC Config
//

// CIDR block for VPC ~ as large as possible for now
variable "cidr_block" {
    default = "10.0.0.0/16"
}

variable "environment_name" {
    default = "kodingterraformtest"
}

variable "aws_availability_zones" {
    default = {
       sa-east-1 = "sa-east-1a"
    }
}

// ami-cf43f9d2 - sa-east-1    trusty  14.04 LTS   amd64   hvm:ebs
variable "koding_test_instance_amis" {
    default = {
        sa-east-1 = "ami-cf43f9d2"
    }
}



// Spin up the VPC.
resource "aws_vpc" "vpc" {
    cidr_block = "${var.cidr_block}"

    tags {
        Name = "${var.environment_name}"
    }
}

//
resource "aws_internet_gateway" "main_vpc_igw" {
    vpc_id = "${aws_vpc.vpc.id}"

    tags {
        Name = "${var.environment_name}"
    }
}

resource "aws_subnet" "main_koding_subnet" {
    vpc_id                  = "${aws_vpc.vpc.id}"
    cidr_block              = "${var.cidr_block}"
    availability_zone       = "${lookup(var.aws_availability_zones, var.aws_region)}"
    map_public_ip_on_launch = true
    tags {
        subnet = "public"
        Name = "${var.environment_name}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main_vpc_igw.id}"
    }

    tags {
        subnet = "public"
        Name = "${var.environment_name}"
        routeTable = "test"
    }
}

resource "aws_route_table_association" "public-1" {
    subnet_id = "${aws_subnet.main_koding_subnet.id}"
    route_table_id = "${aws_route_table.public.id}"
}


// create the security group for other resources
resource "aws_security_group" "allow_all" {
    name = "allow_all"

    description = "Allow all inbound and outbound traffic"

    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        self        = true
    }

    // no need to specify, this one is default
    //egress {
    //  from_port   = 0
    //  to_port     = 65535
    //  protocol    = "-1"
    //  cidr_blocks = ["0.0.0.0/0"]
    //  self        = true
    //}

    vpc_id  = "${aws_vpc.vpc.id}"

    tags {
        Name = "${var.environment_name}"
    }
}

resource "aws_key_pair" "koding_key_pair" {
  key_name = "koding_key_pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8u3tdgzNBq51ZNK0zXW1FziMU90drNgvY8uLi/zNOL1QuBwbRMNNGj/1ZyZmY+hV3VdmexA9AxsOofWEyvzUtL/hkJCmYglWGnTtIawOyDqTXi8Wjz4d00WW69zOiQqpAIAah5ejVsq9gpHslBy4amU+ExcxYoMYoz3ozccim++HkovLr9EhctfJuWvoPtrqljg4D9bn10eR0gdKNROxpnHPfX/Ge7NGcYAsvod5GsUI5zOV3lGfqJTKs+N1jxuqPVUKhoDiEimUQ4SoxBDneETdhRCZRVIQV7cwTfgw+kF58DqgTJCbwzyTyl9n7827Qi1Ha38oWhkAK+cB3uUgT cihangir@koding.com"
}

//resource "aws_instance" "koding_test_instance" {
//    ami = "${lookup(var.koding_test_instance_amis, var.aws_region)}"
//    instance_type = "t2.micro"
//    key_name = "${aws_key_pair.koding_key_pair.key_name}"
//    security_groups = ["${aws_security_group.allow_all.id}"]
//    subnet_id = "${aws_subnet.main_koding_subnet.id}"
//    associate_public_ip_address = true
//    source_dest_check = false
//    tags {
//        Name = "koding_test_instance"
//        subnet = "public"
//        env = "${var.environment_name}"
//    }
//}

//
// VPC related outputs
//
output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
}

output "cidr_block" {
    value = "${aws_vpc.vpc.cidr_block}"
}

output "route_table_id" {
    value = "${aws_vpc.vpc.main_route_table_id}"
}

output "default_network_acl_id" {
    value = "${aws_vpc.vpc.default_network_acl_id}"
}

output "default_security_group_id" {
    value = "${aws_vpc.vpc.default_security_group_id}"
}

/* docs say this exist, it doesn't
output "instance_tenancy" {
    value = "${aws_vpc.vpc.instance_tenancy}"
}
*/

//
// Internet Gateway related outputs
//
output "aws_internet_gateway_id" {
    value = "${aws_internet_gateway.main_vpc_igw.id}"
}

output "aws_main_koding_subnet" {
    value = "${aws_subnet.main_koding_subnet.id}"
}

//
// Security Group Related outputs
//

// Output ID of sg_web SG we made
output "security_group_id_web" {
    value = "${aws_security_group.allow_all.id}"
}


output "koding_key_pair_name" {
    value = "${aws_key_pair.koding_key_pair.key_name}"
}


`
