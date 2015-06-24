package aws

import (
	"fmt"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/iam"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccAWSGroupMembership_basic(t *testing.T) {
	var group iam.GetGroupOutput

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAWSGroupMembershipDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAWSGroupMemberConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSGroupMembershipExists("aws_iam_group_membership.team", &group),
					testAccCheckAWSGroupMembershipAttributes(&group, []string{"test-user"}),
				),
			},

			resource.TestStep{
				Config: testAccAWSGroupMemberConfigUpdate,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckAWSGroupMembershipExists("aws_iam_group_membership.team", &group),
					testAccCheckAWSGroupMembershipAttributes(&group, []string{"test-user-two", "test-user-three"}),
				),
			},
		},
	})
}

func testAccCheckAWSGroupMembershipDestroy(s *terraform.State) error {
	conn := testAccProvider.Meta().(*AWSClient).iamconn

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "aws_iam_group_membership" {
			continue
		}

		group := rs.Primary.Attributes["group"]

		resp, err := conn.GetGroup(&iam.GetGroupInput{
			GroupName: aws.String(group),
		})
		if err != nil {
			// might error here
			return err
		}

		users := []string{"test-user", "test-user-two", "test-user-three"}
		for _, u := range resp.Users {
			for _, i := range users {
				if i == *u.UserName {
					return fmt.Errorf("Error: User (%s) still a member of Group (%s)", i, *resp.Group.GroupName)
				}
			}
		}

	}

	return nil
}

func testAccCheckAWSGroupMembershipExists(n string, g *iam.GetGroupOutput) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[n]
		if !ok {
			return fmt.Errorf("Not found: %s", n)
		}

		if rs.Primary.ID == "" {
			return fmt.Errorf("No User name is set")
		}

		conn := testAccProvider.Meta().(*AWSClient).iamconn
		gn := rs.Primary.Attributes["group"]

		resp, err := conn.GetGroup(&iam.GetGroupInput{
			GroupName: aws.String(gn),
		})

		if err != nil {
			return fmt.Errorf("Error: Group (%s) not found", gn)
		}

		*g = *resp

		return nil
	}
}

func testAccCheckAWSGroupMembershipAttributes(group *iam.GetGroupOutput, users []string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		if *group.Group.GroupName != "test-group" {
			return fmt.Errorf("Bad group membership: expected %s, got %s", "test-group", *group.Group.GroupName)
		}

		uc := len(users)
		for _, u := range users {
			for _, gu := range group.Users {
				if u == *gu.UserName {
					uc--
				}
			}
		}

		if uc > 0 {
			return fmt.Errorf("Bad group membership count, expected (%d), but only (%d) found", len(users), uc)
		}
		return nil
	}
}

const testAccAWSGroupMemberConfig = `
resource "aws_iam_group" "group" {
	name = "test-group"
	path = "/"
}

resource "aws_iam_user" "user" {
	name = "test-user"
	path = "/"
}

resource "aws_iam_group_membership" "team" {
	name = "tf-testing-group-membership"
	users = ["${aws_iam_user.user.name}"]
	group = "${aws_iam_group.group.name}"
}
`

const testAccAWSGroupMemberConfigUpdate = `
resource "aws_iam_group" "group" {
	name = "test-group"
	path = "/"
}

resource "aws_iam_user" "user" {
	name = "test-user"
	path = "/"
}

resource "aws_iam_user" "user_two" {
	name = "test-user-two"
	path = "/"
}

resource "aws_iam_user" "user_three" {
	name = "test-user-three"
	path = "/"
}

resource "aws_iam_group_membership" "team" {
	name = "tf-testing-group-membership"
	users = [
		"${aws_iam_user.user_two.name}",
		"${aws_iam_user.user_three.name}",
	]
	group = "${aws_iam_group.group.name}"
}
`
