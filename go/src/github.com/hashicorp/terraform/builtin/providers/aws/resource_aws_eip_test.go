package aws

import (
	"fmt"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSEIP_basic(t *testing.T) {
	var conf ec2.Address

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSEIPDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSEIPConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSEIPExists("aws_eip.bar", &conf),
					testAccCheckAWSEIPAttributes(&conf),
				),
			},
		},
	})
}

func TestAccAWSEIP_instance(t *testing.T) {
	var conf ec2.Address

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSEIPDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSEIPInstanceConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSEIPExists("aws_eip.bar", &conf),
					testAccCheckAWSEIPAttributes(&conf),
				),
			},

			resource.TestStep{
				Config: testAccAWSEIPInstanceConfig2,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSEIPExists("aws_eip.bar", &conf),
					testAccCheckAWSEIPAttributes(&conf),
				),
			},
		},
	})
}

func TestAccAWSEIP_network_interface(t *testing.T) {
	var conf ec2.Address

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSEIPDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSEIPNetworkInterfaceConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSEIPExists("aws_eip.bar", &conf),
					testAccCheckAWSEIPAttributes(&conf),
					testAccCheckAWSEIPAssociated(&conf),
				),
			},
		},
	})
}

func testAccCheckAWSEIPDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).ec2conn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_eip" {
			continue
		}

		if strings.Contains(rs.Primary.ID, "eipalloc") {
			req := &ec2.DescribeAddressesInput{
				AllocationIds: []*string{aws.String(rs.Primary.ID)},
			}
			describe, err := conn.DescribeAddresses(req)
			if err != nil {
				// Verify the error is what we want
				if ae, ok := err.(awserr.Error); ok && ae.Code() == "InvalidAllocationID.NotFound" {
					continue
				}
				return err
			}

			if len(describe.Addresses) > 0 {
				return fmt.Errorf("still exists")
			}
		} else {
			req := &ec2.DescribeAddressesInput{
				PublicIps: []*string{aws.String(rs.Primary.ID)},
			}
			describe, err := conn.DescribeAddresses(req)
			if err != nil {
				// Verify the error is what we want
				if ae, ok := err.(awserr.Error); ok && ae.Code() == "InvalidAllocationID.NotFound" {
					continue
				}
				return err
			}

			if len(describe.Addresses) > 0 {
				return fmt.Errorf("still exists")
			}
		}
	}

	return nil
}

func testAccCheckAWSEIPAttributes(conf *ec2.Address) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if *conf.PublicIp == "" {
			return fmt.Errorf("empty public_ip")
		}

		return nil
	}
}

func testAccCheckAWSEIPAssociated(conf *ec2.Address) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if *conf.AssociationId == "" {
			return fmt.Errorf("empty association_id")
		}

		return nil
	}
}

func testAccCheckAWSEIPExists(n string, res *ec2.Address) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No EIP ID is set")
		}

		conn := testAccProvider.Meta().(*AWSClient).ec2conn

		if strings.Contains(rs.Primary.ID, "eipalloc") {
			req := &ec2.DescribeAddressesInput{
				AllocationIds: []*string{aws.String(rs.Primary.ID)},
			}
			describe, err := conn.DescribeAddresses(req)
			if err != nil {
				return err
			}

			if len(describe.Addresses) != 1 ||
				*describe.Addresses[0].AllocationId != rs.Primary.ID {
				return fmt.Errorf("EIP not found")
			}
			*res = *describe.Addresses[0]

		} else {
			req := &ec2.DescribeAddressesInput{
				PublicIps: []*string{aws.String(rs.Primary.ID)},
			}
			describe, err := conn.DescribeAddresses(req)
			if err != nil {
				return err
			}

			if len(describe.Addresses) != 1 ||
				*describe.Addresses[0].PublicIp != rs.Primary.ID {
				return fmt.Errorf("EIP not found")
			}
			*res = *describe.Addresses[0]
		}

		return nil
	}
}

const testAccAWSEIPConfig = `
resource "aws_eip" "bar" {
}
`

const testAccAWSEIPInstanceConfig = `
resource "aws_instance" "foo" {
	# us-west-2
	ami = "ami-4fccb37f"
	instance_type = "m1.small"
}

resource "aws_eip" "bar" {
	instance = "${aws_instance.foo.id}"
}
`

const testAccAWSEIPInstanceConfig2 = `
resource "aws_instance" "bar" {
	# us-west-2
	ami = "ami-4fccb37f"
	instance_type = "m1.small"
}

resource "aws_eip" "bar" {
	instance = "${aws_instance.bar.id}"
}
`
const testAccAWSEIPNetworkInterfaceConfig = `
resource "aws_vpc" "bar" {
	cidr_block = "10.0.0.0/24"
}
resource "aws_internet_gateway" "bar" {
	vpc_id = "${aws_vpc.bar.id}"
}
resource "aws_subnet" "bar" {
  vpc_id = "${aws_vpc.bar.id}"
  availability_zone = "us-west-2a"
  cidr_block = "10.0.0.0/24"
}
resource "aws_network_interface" "bar" {
  subnet_id = "${aws_subnet.bar.id}"
	private_ips = ["10.0.0.10"]
  security_groups = [ "${aws_vpc.bar.default_security_group_id}" ]
}
resource "aws_eip" "bar" {
	vpc = "true"
	network_interface = "${aws_network_interface.bar.id}"
}
`
