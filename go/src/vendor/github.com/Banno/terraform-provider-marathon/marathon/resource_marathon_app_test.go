package marathon

import (
	"fmt"
	"io/ioutil"
	"log"
	"regexp"
	"time"

	"github.com/gambol99/go-marathon"
	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"

	"testing"
)

func readExampleAppConfiguration() string {
	bytes, err := ioutil.ReadFile("../test/example.tf")
	if err != nil {
		log.Fatal(err)
	}

	return string(bytes)
}

func readExampleAppConfigurationAndUpdateInstanceCount(count int) string {
	config := readExampleAppConfiguration()
	re := regexp.MustCompile("instances = \\d+")
	updated := re.ReplaceAllString(config, fmt.Sprintf("instances = %d", count))
	return updated
}

func TestAccMarathonApp_basic(t *testing.T) {

	var a marathon.Application

	testCheckCreate := func(app *marathon.Application) resource.TestCheckFunc {
		return func(s *terraform.State) error {
			time.Sleep(1 * time.Second)
			if a.Version == "" {
				return fmt.Errorf("Didn't return a version so something is broken: %#v", app)
			}
			if *a.Instances != 1 {
				return fmt.Errorf("AppCreate: Wrong number of instances %#v", app)
			}
			return nil
		}
	}

	testCheckUpdate := func(app *marathon.Application) resource.TestCheckFunc {
		return func(s *terraform.State) error {
			if *a.Instances != 2 {
				return fmt.Errorf("AppUpdate: Wrong number of instances %#v", app)

			}
			return nil
		}
	}

	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testAccProviders,
		CheckDestroy: testAccCheckMarathonAppDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: readExampleAppConfiguration(),
				Check: resource.ComposeTestCheckFunc(
					testAccReadApp("marathon_app.app-create-example", &a),
					testCheckCreate(&a),
				),
			},
			resource.TestStep{
				Config: readExampleAppConfigurationAndUpdateInstanceCount(2),
				Check: resource.ComposeTestCheckFunc(
					testAccReadApp("marathon_app.app-create-example", &a),
					testCheckUpdate(&a),
				),
			},
		},
	})
}

func testAccReadApp(name string, app *marathon.Application) resource.TestCheckFunc {
	return func(s *terraform.State) error {
		rs, ok := s.RootModule().Resources[name]
		if !ok {
			return fmt.Errorf("marathon_app resource not found: %s", name)
		}
		if rs.Primary.ID == "" {
			return fmt.Errorf("marathon_app resource id not set correctly: %s", name)
		}

		//log.Printf("=== testAccContainerExists: rs ===\n%#v\n", rs)

		config := testAccProvider.Meta().(config)
		client := config.Client

		appRead, _ := client.Application(rs.Primary.Attributes["app_id"])

		//		log.Printf("=== testAccContainerExists: appRead ===\n%#v\n", appRead)

		time.Sleep(5000 * time.Millisecond)

		*app = *appRead

		return nil
	}
}

func testAccCheckMarathonAppDestroy(s *terraform.State) error {
	time.Sleep(5000 * time.Millisecond)

	config := testAccProvider.Meta().(config)
	client := config.Client

	_, err := client.Application("/app-create-example")
	if err == nil {
		return fmt.Errorf("App not deleted! %#v", err)
	}

	return nil
}
