package vagrant

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
	testVagrantBuildConfig = `
resource "vagrant_instance" "myfirstvm" {
	filePath = ` + vagrantFilePath + `
    queryString = ` + queryString + `
    vagrantFile = ` + vagrantFile + `
}
`
	queryString = "///////8c396fd6-c91c-4454-45c2-5c461ad32645"

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
	vagrantFilePath = "/home/etc/Vagrantfile"
)

func TestVagrantProviderConfig(t *testing.T) {
	resource.Test(t, resource.TestCase{
		Providers: testVagrantResourceProviders,
		Steps: []resource.TestStep{
			{
				Config: testVagrantBuildConfig,
				Check: resource.ComposeTestCheckFunc(
					resource.TestCheckResourceAttr(
						"vagrant_instance.myfirstvm",
						"filePath",
						vagrantFilePath,
					),
					resource.TestCheckResourceAttr(
						"vagrant_instance.myfirstvm",
						"queryString",
						queryString,
					),
					resource.TestCheckResourceAttr(
						"vagrant_instance.myfirstvm",
						"vagrantFile",
						vagrantFile,
					),
				),
			},
		},
	})
}

func TestSendingCommandSuccess(t *testing.T) {
	withClient(t, func(c *Client) error {

		args := &vagrantReq{
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

		args := &vagrantReq{
			VagrantFile: vagrantFile + "some random dude to make test fail",
			FilePath:    vagrantFilePath,
		}

		queryString := c.Kite.Kite().String()

		if err := sendCommand(klientFuncName, queryString, args); err != nil {
			return nil
		}

		return errors.New("failure should happen")
	})
}

func withClient(t *testing.T, f func(c *Client) error) {
	client, err := NewClient()
	if err != nil {
		t.Errorf(err.Error())
	}
	defer client.Close()

	client.Kite.Config.DisableAuthentication = true
	client.Kite.Config.Port = 5000
	client.Kite.HandleFunc(klientFuncName, mockHandler)

	go client.Kite.Run()
	<-client.Kite.ServerReadyNotify()

	queryString := &url.URL{
		Scheme: "http",
		Host:   "localhost:" + strconv.Itoa(client.Kite.Port()),
		Path:   "/kite",
	}

	if _, err := client.Kite.Register(queryString); err != nil {
		t.Errorf("couldnt register to kontrol %s", err.Error())
	}

	if err := f(client); err != nil {
		t.Errorf("failed with %s", err.Error())
	}
}

var mockHandler = func(r *kite.Request) (interface{}, error) {
	var res []vagrantReq // another slice??
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
