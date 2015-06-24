package aws

import (
	"fmt"
	"testing"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSMainRouteTableAssociation_basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckMainRouteTableAssociationDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccMainRouteTableAssociationConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckMainRouteTableAssociation(
						"aws_main_route_table_association.foo",
						"aws_vpc.foo",
						"aws_route_table.foo",
					),
				),
			},
			resource.TestStep{
				Config: testAccMainRouteTableAssociationConfigUpdate,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckMainRouteTableAssociation(
						"aws_main_route_table_association.foo",
						"aws_vpc.foo",
						"aws_route_table.bar",
					),
				),
			},
		},
	})
}

func testAccCheckMainRouteTableAssociationDestroy(s *terraform.State) error {
	if len(s.RootModule().Resources) > 0 {
		return fmt.Errorf("Expected all resources to be gone, but found: %#v", s.RootModule().Resources)
	}

	return nil
}

func testAccCheckMainRouteTableAssociation(
	mainRouteTableAssociationResource string,
	vpcResource string,
	routeTableResource string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[mainRouteTableAssociationResource]
		if !ok {
			return fmt.Errorf("Not found: %s", mainRouteTableAssociationResource)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No ID is set")
		}

		vpc, ok := s.RootModule().Resources[vpcResource]
		if !ok {
			return fmt.Errorf("Not found: %s", vpcResource)
		}

		conn := testAccProvider.Meta().(*AWSClient).ec2conn
		mainAssociation, err := findMainRouteTableAssociation(conn, vpc.Primary.ID)
		if err != nil {
			return err
		}

		if *mainAssociation.RouteTableAssociationID != rs.Primary.ID {
			return fmt.Errorf("Found wrong main association: %s",
				*mainAssociation.RouteTableAssociationID)
		}

		return nil
	}
}

const testAccMainRouteTableAssociationConfig = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	cidr_block = "10.1.1.0/24"
}

resource "aws_internet_gateway" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
}

resource "aws_route_table" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	route {
		cidr_block = "10.0.0.0/8"
		gateway_id = "${aws_internet_gateway.foo.id}"
	}
}

resource "aws_main_route_table_association" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	route_table_id = "${aws_route_table.foo.id}"
}
`

const testAccMainRouteTableAssociationConfigUpdate = `
resource "aws_vpc" "foo" {
	cidr_block = "10.1.0.0/16"
}

resource "aws_subnet" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	cidr_block = "10.1.1.0/24"
}

resource "aws_internet_gateway" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
}

// Need to keep the old route table around when we update the
// main_route_table_association, otherwise Terraform will try to destroy the
// route table too early, and will fail because it's still the main one
resource "aws_route_table" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	route {
		cidr_block = "10.0.0.0/8"
		gateway_id = "${aws_internet_gateway.foo.id}"
	}
}

resource "aws_route_table" "bar" {
	vpc_id = "${aws_vpc.foo.id}"
	route {
		cidr_block = "10.0.0.0/8"
		gateway_id = "${aws_internet_gateway.foo.id}"
	}
}

resource "aws_main_route_table_association" "foo" {
	vpc_id = "${aws_vpc.foo.id}"
	route_table_id = "${aws_route_table.bar.id}"
}
`
