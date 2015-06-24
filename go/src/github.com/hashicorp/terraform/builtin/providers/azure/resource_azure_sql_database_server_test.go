package azure

import (
	"fmt"
	"testing"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
)

// testAccAzureSqlServerName is a helper variable in which to store
// the randomly-generated name of the SQL Server after it is created.
// The anonymous function is there because go is too good to &"" directly.
var testAccAzureSqlServerName *string = func(s string) *string { return &s }("")

func TestAccAzureSqlDatabaseServer(t *testing.T) {
	name := "azure_sql_database_server.foo"
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckAzureSqlDatabaseServerDeleted,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testAccAzureSqlDatabaseServerConfig,
				Check: resource.ComposeTestCheckFunc(
					testAccAzureSqlDatabaseServerGetName,
					testAccCheckAzureSqlDatabaseServerExists(name),
					resource.TestCheckResourceAttrPtr(name, "name", testAccAzureSqlServerName),
					resource.TestCheckResourceAttr(name, "username", "SuperUser"),
					resource.TestCheckResourceAttr(name, "password", "SuperSEKR3T"),
					resource.TestCheckResourceAttr(name, "version", "2.0"),
				),
			},
		},
	})
}

func testAccCheckAzureSqlDatabaseServerExists(name string) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		resource, ok := s.RootModule().Resources[name]
		if !ok {
			return fmt.Errorf("SQL Server %s doesn't exist.", name)
		}

		if resource.Primary.ID == "" {
			return fmt.Errorf("SQL Server %s resource ID not set.", name)
		}

		sqlClient := testAccProvider.Meta().(*Client).sqlClient
		servers, err := sqlClient.ListServers()
		if err != nil {
			return fmt.Errorf("Error issuing Azure SQL Server list request: %s", err)
		}

		for _, srv := range servers.DatabaseServers {
			if srv.Name == resource.Primary.ID {
				return nil
			}
		}

		return fmt.Errorf("SQL Server %s doesn't exist.", name)
	}
}

func testAccCheckAzureSqlDatabaseServerDeleted(s *terraform.State) error {
	for _, resource := range s.RootModule().Resources {
		if resource.Type != "azure_sql_database_server" {
			continue
		}

		if resource.Primary.ID == "" {
			return fmt.Errorf("SQL Server resource ID not set.")
		}

		sqlClient := testAccProvider.Meta().(*Client).sqlClient
		servers, err := sqlClient.ListServers()
		if err != nil {
			return fmt.Errorf("Error issuing Azure SQL Server list request: %s", err)
		}

		for _, srv := range servers.DatabaseServers {
			if srv.Name == resource.Primary.ID {
				fmt.Errorf("SQL Server %s still exists.", resource.Primary.ID)
			}
		}
	}
	return nil
}

// testAccAzureSqlDatabaseServerGetName is ahelper function which reads the current
// state form Terraform and sets the testAccAzureSqlServerName variable
// to the ID (which is actually the name) of the newly created server.
// It is modeled as a resource.TestCheckFunc so as to be easily-embeddable in
// test cases and run live.
func testAccAzureSqlDatabaseServerGetName(s *terraform.State) error {
	for _, resource := range s.RootModule().Resources {
		if resource.Type != "azure_sql_database_server" {
			continue
		}

		if resource.Primary.ID == "" {
			return fmt.Errorf("Azure SQL Server resource ID not set.")
		}

		*testAccAzureSqlServerName = resource.Primary.ID
		return nil
	}

	return fmt.Errorf("No Azure SQL Servers found.")
}

const testAccAzureSqlDatabaseServerConfig = `
resource "azure_sql_database_server" "foo" {
    location = "West US"
    username = "SuperUser"
    password = "SuperSEKR3T"
    version = "2.0"
}
`
