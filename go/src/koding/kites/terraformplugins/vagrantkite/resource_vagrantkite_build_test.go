package vagrantkite

import (
	"fmt"
	"testing"

	"github.com/koding/kite"

	"github.com/hashicorp/terraform/helper/resource"
	"github.com/hashicorp/terraform/terraform"
	"github.com/kr/pretty"
)

func TestAccGithubAddUser_Basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:     func() { testAccPreCheck(t) },
		Providers:    testVagrantResourceProviders,
		CheckDestroy: testAccCheckGithubAddUserDestroy,
		Steps: []resource.TestStep{
			resource.TestStep{
				Config: testVagrantKiteBuildConfig,
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr(
						"vagrantkite_build.myfirstvm",
						"kiteURL",
						"////////test",
					),
				),
			},
		},
	})
}

func testAccCheckGithubAddUserDestroy(s *terraform.State) error {
	// client := testVagrantProvider.Meta().(*Clients).OrgClient

	// for _, rs := range s.RootModule().Resources {
	// 	if rs.Type != "vagrantkite_build" {
	// 		continue
	// 	}

	// 	_, err := client.Organizations.RemoveMember(rs.Primary.Attributes["organization"], rs.Primary.Attributes["username"])

	// 	if err != nil {
	// 		fmt.Println("something wrong with removing member from organization %v", err.Error())
	// 	}
	// }

	return nil
}

const (
	testVagrantKiteBuildConfig = `
resource "vagrantkite_build" "myfirstvm" {
    kiteURL = "////////test"
}
`
	vagrantFile = `# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "vagrant"

  config.vm.provider "virtualbox" do |vb|
    # Use VBoxManage to customize the VM. For example to change memory:
    vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
  end
end
`
)

var mockHandler = func(r *kite.Request) (interface{}, error) {
	vagrantFile, err := r.Args.String()
	if err != nil {
		return nil, err
	}

	fmt.Printf("vagrantFile %# v", pretty.Formatter(vagrantFile))
	return nil, nil
}

func withClient(t *testing.T, f func(c *Client) error) {
	client, err := NewClient()
	if err != nil {
		t.Errorf(err.Error())
	}

	k := client.Kite
	k.HandleFunc(klientFuncName, mockHandler)
	k.Config.DisableAuthentication = true
	go k.Run()
	<-k.ServerReadyNotify()

	err = f(client)
	k.Close()
	if err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

func TestApplyAndDestroy(t *testing.T) {
	local := kite.New("testing", "1.0.0")
	go local.Run()
	<-local.ServerReadyNotify()

	withClient(t, func(c *Client) error {
		k := c.Kite
		// Connect to our terraformer kite
		tfr := local.NewClient(k.RegisterURL(true).String())
		defer tfr.Close()

		tfr.Dial()

		response, err := tfr.Tell(klientFuncName, vagrantFile)
		fmt.Printf("err %# v", pretty.Formatter(err))
		if err != nil {
			return err
		}

		res, err := response.String()
		fmt.Printf("err %# v", pretty.Formatter(err))
		if err != nil {
			return err
		}

		fmt.Printf("res %# v", pretty.Formatter(res))
		return nil
	})

}
