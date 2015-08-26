package vagrantkite

import (
	"errors"
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

	kiteURL := &url.URL{
		Scheme: "http",
		Host:   "localhost:" + strconv.Itoa(client.Kite.Port()),
		Path:   "/kite",
	}

	if _, err := client.Kite.Register(kiteURL); err != nil {
		t.Errorf("couldnt register to kontrol %s", err.Error())
	}

	err = f(client)
	client.Kite.Close()
	if err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

func TestSendingCommandSuccess(t *testing.T) {
	withClient(t, func(c *Client) error {

		args := &vagrantKiteReq{
			VagrantFile: vagrantFile,
			FilePath:    vagrantFilePath,
		}

		queryString := c.Kite.Kite().String()

		if err := sendCommand(klientFuncName, queryString, args); err != nil {
			return err
		}

		return nil
	})
}

func TestSendingCommandFailure(t *testing.T) {
	withClient(t, func(c *Client) error {

		args := &vagrantKiteReq{
			VagrantFile: vagrantFile + "1",
			FilePath:    vagrantFilePath,
		}

		queryString := c.Kite.Kite().String()

		if err := sendCommand(klientFuncName, queryString, args); err != nil {
			return nil
		}

		return errors.New("failure should happen")
	})
}

var mockHandler = func(r *kite.Request) (interface{}, error) {
	var res []vagrantKiteReq // another slice??
	if err := r.Args.Unmarshal(&res); err != nil {
		return nil, fmt.Errorf("err while unmarshalling: %s", err.Error())
	}

	if res[0].FilePath != vagrantFilePath {
		return nil, fmt.Errorf("filePath is %+v, expected %+v", res[0].FilePath, vagrantFilePath)
	}

	if res[0].VagrantFile != vagrantFile {
		return nil, fmt.Errorf("vagrantFile is %+v, expected %+v", res[0].VagrantFile, vagrantFile)
	}

	return res, nil
}
