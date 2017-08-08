package aws

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSNetworkAcl_EgressAndIngressRules(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.bar",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclEgressNIngressConfig,
				Check: resource.ComposeAggregateTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.bar", &networkAcl),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.rule_no", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.from_port", "80"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.to_port", "80"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.action", "allow"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "ingress.1871939009.cidr_block", "10.3.0.0/18"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.rule_no", "2"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.from_port", "443"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.to_port", "443"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.cidr_block", "10.3.0.0/18"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.bar", "egress.3111164687.action", "allow"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_OnlyIngressRules_basic(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.foos",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclIngressConfig,
				Check: resource.ComposeAggregateTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.foos", &networkAcl),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.rule_no", "2"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.from_port", "443"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.to_port", "443"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.action", "deny"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.cidr_block", "10.2.0.0/18"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_OnlyIngressRules_update(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.foos",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclIngressConfig,
				Check: resource.ComposeAggregateTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.foos", &networkAcl),
					testIngressRuleLength(&networkAcl, 2),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.rule_no", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.from_port", "0"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.to_port", "22"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.action", "deny"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.cidr_block", "10.2.0.0/18"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.from_port", "443"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.4245812720.rule_no", "2"),
				),
			},
			{
				Config: testAccAWSNetworkAclIngressConfigChange,
				Check: resource.ComposeAggregateTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.foos", &networkAcl),
					testIngressRuleLength(&networkAcl, 1),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.rule_no", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.from_port", "0"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.to_port", "22"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.action", "deny"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.401088754.cidr_block", "10.2.0.0/18"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_OnlyEgressRules(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.bond",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclEgressConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.bond", &networkAcl),
					testAccCheckTags(&networkAcl.Tags, "foo", "bar"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_SubnetChange(t *testing.T) {

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.bar",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclSubnetConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.old"),
				),
			},
			{
				Config: testAccAWSNetworkAclSubnetConfigChange,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckSubnetIsNotAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.old"),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.new"),
				),
			},
		},
	})

}

func TestAccAWSNetworkAcl_Subnets(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	checkACLSubnets := func(acl *ec2.NetworkAcl, count int) resource.TestCheckFunc {
		return func(*terraform.State) (err error) {
			if count != len(acl.Associations) {
				return fmt.Errorf("ACL association count does not match, expected %d, got %d", count, len(acl.Associations))
			}

			return nil
		}
	}

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.bar",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclSubnet_SubnetIds,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.bar", &networkAcl),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.one"),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.two"),
					checkACLSubnets(&networkAcl, 2),
				),
			},

			{
				Config: testAccAWSNetworkAclSubnet_SubnetIdsUpdate,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.bar", &networkAcl),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.one"),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.three"),
					testAccCheckSubnetIsAssociatedWithAcl("aws_network_acl.bar", "aws_subnet.four"),
					checkACLSubnets(&networkAcl, 3),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_ipv6Rules(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.foos",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclIpv6Config,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.foos", &networkAcl),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.#", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.protocol", "6"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.rule_no", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.from_port", "0"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.to_port", "22"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.action", "allow"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1976110835.ipv6_cidr_block", "::/0"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_ipv6VpcRules(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.foos",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclIpv6VpcConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.foos", &networkAcl),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.#", "1"),
					resource.TestCheckResourceAttr(
						"aws_network_acl.foos", "ingress.1296304962.ipv6_cidr_block", "2600:1f16:d1e:9a00::/56"),
				),
			},
		},
	})
}

func TestAccAWSNetworkAcl_espProtocol(t *testing.T) {
	var networkAcl ec2.NetworkAcl

	resource.Test(t, resource.TestCase{
		PreCheck:      func() { testAccPreCheck(t) },
		IDRefreshName: "aws_network_acl.testesp",
		Providers:     testAccProviders,
		CheckDestroy:  testAccCheckAWSNetworkAclDestroy,
		Steps: []resource.TestStep{
			{
				Config: testAccAWSNetworkAclEsp,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSNetworkAclExists("aws_network_acl.testesp", &networkAcl),
				),
			},
		},
	})
}

func testAccCheckAWSNetworkAclDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).ec2conn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_network" {
			continue
		}

		// Retrieve the network acl
		resp, err := conn.DescribeNetworkAcls(&ec2.DescribeNetworkAclsInput{
			NetworkAclIds: []*string{aws.String(rs.Primary.ID)},
		})
		if err == nil {
			if len(resp.NetworkAcls) > 0 && *resp.NetworkAcls[0].NetworkAclId == rs.Primary.ID {
				return fmt.Errorf("Network Acl (%s) still exists.", rs.Primary.ID)
			}

			return nil
		}

		ec2err, ok := err.(awserr.Error)
		if !ok {
			return err
		}
		// Confirm error code is what we want
		if ec2err.Code() != "InvalidNetworkAclID.NotFound" {
			return err
		}
	}

	return nil
}

func testAccCheckAWSNetworkAclExists(n string, networkAcl *ec2.NetworkAcl) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No Security Group is set")
		}
		conn := testAccProvider.Meta().(*AWSClient).ec2conn

		resp, err := conn.DescribeNetworkAcls(&ec2.DescribeNetworkAclsInput{
			NetworkAclIds: []*string{aws.String(rs.Primary.ID)},
		})
		if err != nil {
			return err
		}

		if len(resp.NetworkAcls) > 0 && *resp.NetworkAcls[0].NetworkAclId == rs.Primary.ID {
			*networkAcl = *resp.NetworkAcls[0]
			return nil
		}

		return fmt.Errorf("Network Acls not found")
	}
}

func testIngressRuleLength(networkAcl *ec2.NetworkAcl, length int) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		var ingressEntries []*ec2.NetworkAclEntry
		for _, e := range networkAcl.Entries {
			if *e.Egress == false {
				ingressEntries = append(ingressEntries, e)
			}
		}
		// There is always a default rule (ALL Traffic ... DENY)
		// so we have to increase the length by 1
		if len(ingressEntries) != length+1 {
			return fmt.Errorf("Invalid number of ingress entries found; count = %d", len(ingressEntries))
		}
		return nil
	}
}

func testAccCheckSubnetIsAssociatedWithAcl(acl string, sub string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		networkAcl := s.RootModule().Resources[acl]
		subnet := s.RootModule().Resources[sub]

		conn := testAccProvider.Meta().(*AWSClient).ec2conn
		resp, err := conn.DescribeNetworkAcls(&ec2.DescribeNetworkAclsInput{
			NetworkAclIds: []*string{aws.String(networkAcl.Primary.ID)},
			Filters: []*ec2.Filter{
				{
					Name:   aws.String("association.subnet-id"),
					Values: []*string{aws.String(subnet.Primary.ID)},
				},
			},
		})
		if err != nil {
			return err
		}
		if len(resp.NetworkAcls) > 0 {
			return nil
		}

		return fmt.Errorf("Network Acl %s is not associated with subnet %s", acl, sub)
	}
}

func testAccCheckSubnetIsNotAssociatedWithAcl(acl string, subnet string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		networkAcl := s.RootModule().Resources[acl]
		subnet := s.RootModule().Resources[subnet]

		conn := testAccProvider.Meta().(*AWSClient).ec2conn
		resp, err := conn.DescribeNetworkAcls(&ec2.DescribeNetworkAclsInput{
			NetworkAclIds: []*string{aws.String(networkAcl.Primary.ID)},
			Filters: []*ec2.Filter{
				{
					Name:   aws.String("association.subnet-id"),
					Values: []*string{aws.String(subnet.Primary.ID)},
				},
			},
		})

		if err != nil {
			return err
		}
		if len(resp.NetworkAcls) > 0 {
			return fmt.Errorf("Network Acl %s is still associated with subnet %s", acl, subnet)
		}
		return nil
	}
}

const testAccAWSNetworkAclIpv6Config = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_ipv6Rules"
	}
}
resource "aws_subnet" "blob" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "foos" {
	vpc_id = "${aws_vpc.foo.id}"
	ingress = {
		protocol = "tcp"
		rule_no = 1
		action = "allow"
		ipv6_cidr_block =  "::/0"
		from_port = 0
		to_port = 22
	}

	subnet_ids = ["${aws_subnet.blob.id}"]
}
`

const testAccAWSNetworkAclIpv6VpcConfig = `
provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	assign_generated_ipv6_cidr_block = true

	tags {
		Name = "TestAccAWSNetworkAcl_ipv6VpcRules"
	}
}

resource "aws_network_acl" "foos" {
	vpc_id = "${aws_vpc.foo.id}"
	ingress = {
		protocol = "tcp"
		rule_no = 1
		action = "allow"
		ipv6_cidr_block =  "2600:1f16:d1e:9a00::/56"
		from_port = 0
		to_port = 22
	}
}
`

const testAccAWSNetworkAclIngressConfig = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_OnlyIngressRules"
	}
}
resource "aws_subnet" "blob" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "foos" {
	vpc_id = "${aws_vpc.foo.id}"
	ingress = {
		protocol = "tcp"
		rule_no = 1
		action = "deny"
		cidr_block =  "10.2.0.0/18"
		from_port = 0
		to_port = 22
	}
	ingress = {
		protocol = "tcp"
		rule_no = 2
		action = "deny"
		cidr_block =  "10.2.0.0/18"
		from_port = 443
		to_port = 443
	}

	subnet_ids = ["${aws_subnet.blob.id}"]
}
`
const testAccAWSNetworkAclIngressConfigChange = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_OnlyIngressRules"
	}
}
resource "aws_subnet" "blob" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "foos" {
	vpc_id = "${aws_vpc.foo.id}"
	ingress = {
		protocol = "tcp"
		rule_no = 1
		action = "deny"
		cidr_block =  "10.2.0.0/18"
		from_port = 0
		to_port = 22
	}
	subnet_ids = ["${aws_subnet.blob.id}"]
}
`

const testAccAWSNetworkAclEgressConfig = `
resource "aws_vpc" "foo" {
	cidr_block = "10.2.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_OnlyEgressRules"
	}
}
resource "aws_subnet" "blob" {
	cidr_block = "10.2.0.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "bond" {
	vpc_id = "${aws_vpc.foo.id}"
	egress = {
		protocol = "tcp"
		rule_no = 2
		action = "allow"
		cidr_block =  "10.2.0.0/18"
		from_port = 443
		to_port = 443
	}

	egress = {
		protocol = "-1"
		rule_no = 4
		action = "allow"
		cidr_block = "0.0.0.0/0"
		from_port = 0
		to_port = 0
	}

	egress = {
		protocol = "tcp"
		rule_no = 1
		action = "allow"
		cidr_block =  "10.2.0.0/18"
		from_port = 80
		to_port = 80
	}

	egress = {
		protocol = "tcp"
		rule_no = 3
		action = "allow"
		cidr_block =  "10.2.0.0/18"
		from_port = 22
		to_port = 22
	}

	tags {
		foo = "bar"
	}
}
`

const testAccAWSNetworkAclEgressNIngressConfig = `
resource "aws_vpc" "foo" {
	cidr_block = "10.3.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_EgressAndIngressRules"
	}
}
resource "aws_subnet" "blob" {
	cidr_block = "10.3.0.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	egress = {
		protocol = "tcp"
		rule_no = 2
		action = "allow"
		cidr_block =  "10.3.0.0/18"
		from_port = 443
		to_port = 443
	}

	ingress = {
		protocol = "tcp"
		rule_no = 1
		action = "allow"
		cidr_block =  "10.3.0.0/18"
		from_port = 80
		to_port = 80
	}
}
`
const testAccAWSNetworkAclSubnetConfig = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_SubnetChange"
	}
}
resource "aws_subnet" "old" {
	cidr_block = "10.1.111.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_subnet" "new" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "roll" {
	vpc_id = "${aws_vpc.foo.id}"
	subnet_ids = ["${aws_subnet.new.id}"]
}
resource "aws_network_acl" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	subnet_ids = ["${aws_subnet.old.id}"]
}
`

const testAccAWSNetworkAclSubnetConfigChange = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_SubnetChange"
	}
}
resource "aws_subnet" "old" {
	cidr_block = "10.1.111.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_subnet" "new" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	map_public_ip_on_launch = true
}
resource "aws_network_acl" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	subnet_ids = ["${aws_subnet.new.id}"]
}
`

const testAccAWSNetworkAclSubnet_SubnetIds = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_Subnets"
	}
}
resource "aws_subnet" "one" {
	cidr_block = "10.1.111.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}
resource "aws_subnet" "two" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}
resource "aws_network_acl" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	subnet_ids = ["${aws_subnet.one.id}", "${aws_subnet.two.id}"]
	tags {
		Name = "acl-subnets-test"
	}
}
`

const testAccAWSNetworkAclSubnet_SubnetIdsUpdate = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
	tags {
		Name = "TestAccAWSNetworkAcl_Subnets"
	}
}
resource "aws_subnet" "one" {
	cidr_block = "10.1.111.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}
resource "aws_subnet" "two" {
	cidr_block = "10.1.1.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}

resource "aws_subnet" "three" {
	cidr_block = "10.1.222.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}
resource "aws_subnet" "four" {
	cidr_block = "10.1.4.0/24"
	vpc_id = "${aws_vpc.foo.id}"
	tags {
		Name = "acl-subnets-test"
	}
}
resource "aws_network_acl" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	subnet_ids = [
		"${aws_subnet.one.id}",
		"${aws_subnet.three.id}",
		"${aws_subnet.four.id}",
	]
	tags {
		Name = "acl-subnets-test"
	}
}
`

const testAccAWSNetworkAclEsp = `
resource "aws_vpc" "testespvpc" {
  cidr_block = "10.1.0.0/16"
	tags {
		Name = "testAccAWSNetworkAclEsp"
	}
}

resource "aws_network_acl" "testesp" {
  vpc_id = "${aws_vpc.testespvpc.id}"

  egress {
    protocol   = "esp"
    rule_no    = 5
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "test_esp"
  }
}
`
