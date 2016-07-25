package githubprovider

import (
	"fmt"
	"testing"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

func TestAccGithubAddUser_Basic(t *testing.T) {

	resource.Test(t, resource.TestCase{
		PreCheck:          func() { testAccPreCheck(t) },
		Providers:         testAccProviders,
		CheckDestroy:      testAccCheckGithubAddUserDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccCheckGithubAddUserConfig_basic,
				Check: resource.ComposeTestCheckFunc(
					testAccCheckGithubAddUserExists("github_AddUser.foobar"),
					resource.TestCheckResourceAttr(
						"github_AddUser.foobar", "username", "cihangir"),
					resource.TestCheckResourceAttr(
						"github_AddUser.foobar", "organization", "organizasyon"),
				),
			},
		},
	})
}

func testAccCheckGithubAddUserDestroy(s *terraform.State) error {
	client := testAccProvider.Meta().(*Clients).OrgClient

	for _, rs := range s.RootModule().Resources {
		if rs.Type != "github_adduser" {
			continue
		}

		_, err := client.Organizations.RemoveMember(rs.Primary.Attributes["organization"], rs.Primary.Attributes["username"])

		if err != nil {
			fmt.Println("something wrong with removing member from organization %v", err.Error())
		}
	}

	return nil
}

func testAccCheckGithubAddUserExists(n string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		_, ok := s.RootModule().Resources[n]

		if !ok {
			return fmt.Errorf("Not found: %s, res: %#v", n, s.RootModule())
		}

		return nil
	}
}

const testAccCheckGithubAddUserConfig_basic = `
resource "github_adduser" "foobar" {
    username = "cihangir"
    organization = "organizasyon"
    teams = ["tigm"]
}
`


