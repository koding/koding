package softlayer

import (
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/userdata"
	"log"
	"time"

	"github.com/kr/pretty"
	datatypes "github.com/maximilien/softlayer-go/data_types"
	"github.com/nu7hatch/gouuid"
	"golang.org/x/net/context"
)

func (m *Machine) Build(ctx context.Context) (err error) {
	if err := m.UpdateState(machinestate.Building); err != nil {
		return err
	}

	keys, ok := publickeys.FromContext(ctx)
	if !ok {
		return errors.New("public keys are not available")
	}

	sshKeys := make([]string, len(m.User.SshKeys))
	for i, sshKey := range m.User.SshKeys {
		sshKeys[i] = sshKey.Key
	}

	// also append our own public key so we can use it ssh into the machine and debug it
	sshKeys = append(sshKeys, keys.PublicKey)

	kiteUUID, err := uuid.NewV4()
	if err != nil {
		return err
	}
	kiteId := kiteUUID.String()

	cloudInitConfig := &userdata.CloudInitConfig{
		Username:    m.Username,
		Groups:      []string{"sudo"},
		UserSSHKeys: sshKeys,
		Hostname:    m.Username, // no typo here. hostname = username
		KiteId:      kiteId,
	}

	userdata, err := m.Session.Userdata.Create(cloudInitConfig)
	if err != nil {
		return err
	}

	//Create a template for the virtual guest (changing properties as needed)
	virtualGuestTemplate := datatypes.SoftLayer_Virtual_Guest_Template{
		Hostname:  "koding-" + m.Username,
		Domain:    "koding.io", // this is just a placeholder
		StartCpus: 1,
		MaxMemory: 1024,
		Datacenter: datatypes.Datacenter{
			Name: "ams01",
		},
		HourlyBillingFlag:            true,
		LocalDiskFlag:                true,
		OperatingSystemReferenceCode: "UBUNTU_LATEST",
		UserData: []datatypes.UserData{
			{Value: string(userdata)},
		},
	}

	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	//Create the virtual guest with the service
	obj, err := svc.CreateObject(virtualGuestTemplate)
	if err != nil {
		return err
	}

	pretty.Println(obj)

	for i := 0; i < 10; i++ {
		fmt.Println("------------------")
		fmt.Println("")
		time.Sleep(time.Second * 5)

		o, err := svc.GetObject(obj.Id)
		if err != nil {
			log.Println("err", err)
		}

		pretty.Println(o)
	}

	fmt.Println("build finished!")
	return nil
}
