package vagrantkite

import (
	"fmt"
	"net/url"
	"strconv"
	"testing"

	"github.com/koding/kite"

	"github.com/hashicorp/terraform/helper/resource"
)

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
	vagrantFilePath = "/home/etc"
)

func TestAccGithubAddUser_Basic(t *testing.T) {
	resource.Test(t, resource.TestCase{
		// PreCheck:  func() { testAccPreCheck(t) },
		Providers: testVagrantResourceProviders,
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

var mockHandler = func(r *kite.Request) (interface{}, error) {
	var req []vagrantKiteReq // why slice?
	err := r.Args.Unmarshal(&req)
	if err != nil {
		return nil, err
	}

	return req, nil
}

func withClient(t *testing.T, f func(c *Client) error) {
	client, err := NewClient()
	if err != nil {
		t.Errorf(err.Error())
	}

	client.Kite.Config.DisableAuthentication = true
	client.Kite.Config.Port = 5000
	client.Kite.HandleFunc(klientFuncName, mockHandler)

	go client.Kite.Run()
	<-client.Kite.ServerReadyNotify()

	err = f(client)
	client.Kite.Close()
	if err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

func TestSendingCommand(t *testing.T) {
	local := kite.New("testing", "1.0.0")
	withClient(t, func(c *Client) error {

		kiteURL := &url.URL{
			Scheme: "http",
			Host:   "localhost:" + strconv.Itoa(c.Kite.Port()),
			Path:   "/kite",
		}

		tfr := local.NewClient(kiteURL.String())
		defer tfr.Close()

		tfr.Dial()

		args := &vagrantKiteReq{
			VagrantFile: vagrantFile,
			FilePath:    vagrantFilePath,
		}

		response, err := tfr.Tell(klientFuncName, args)
		if err != nil {
			return err
		}

		var res []vagrantKiteReq // another slice??

		if err := response.Unmarshal(&res); err != nil {
			return err
		}

		if res[0].FilePath != vagrantFilePath {
			return fmt.Errorf("filePath is %+v, expected %+v", res[0].FilePath, vagrantFilePath)
		}

		if res[0].VagrantFile != vagrantFile {
			return fmt.Errorf("vagrantFile is %+v, expected %+v", res[0].VagrantFile, vagrantFile)
		}

		return nil
	})
}
