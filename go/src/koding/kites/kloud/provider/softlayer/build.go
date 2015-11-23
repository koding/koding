package softlayer

import (
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/machinestate"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/kite/protocol"
	"github.com/kr/pretty"
	datatypes "github.com/maximilien/softlayer-go/data_types"
	"github.com/maximilien/softlayer-go/softlayer"
	"github.com/nu7hatch/gouuid"
	"golang.org/x/net/context"
)

const (
	// Go binary residues at go/src/koding/kites/kloud/scripts/softlayer
	PostInstallScriptUri = "https://s3.amazonaws.com/kodingdev-softlayer/softlayer"
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

	// cloudInitConfig := &userdata.CloudInitConfig{
	// 	Username:    m.Username,
	// 	Groups:      []string{"sudo"},
	// 	UserSSHKeys: sshKeys,
	// 	Hostname:    m.Username, // no typo here. hostname = username
	// 	KiteId:      kiteId,
	// }

	// userdata, err := m.Session.Userdata.Create(cloudInitConfig)
	// if err != nil {
	// 	return err
	// }

	//Create a template for the virtual guest (changing properties as needed)
	virtualGuestTemplate := datatypes.SoftLayer_Virtual_Guest_Template{
		Hostname:  "koding-" + m.Username,
		Domain:    "koding.io", // this is just a placeholder
		StartCpus: 1,
		MaxMemory: 1024,
		Datacenter: datatypes.Datacenter{
			Name: "fra02",
		},
		HourlyBillingFlag:            true,
		LocalDiskFlag:                true,
		OperatingSystemReferenceCode: "UBUNTU_LATEST",
		UserData: []datatypes.UserData{
			{Value: "vim-go"},
		},
		PostInstallScriptUri: PostInstallScriptUri,
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

	// wait until it's ready
	if err := waitState(svc, obj.Id, "RUNNING"); err != nil {
		return err
	}

	// get final information, such as public IP address and co
	obj, err = svc.GetObject(obj.Id)
	if err != nil {
		return err
	}

	pretty.Println(obj)

	m.QueryString = protocol.Kite{ID: kiteId}.String()
	m.IpAddress = obj.PrimaryIpAddress

	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	fmt.Println("build finished!")
	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         m.IpAddress,
				"queryString":       m.QueryString,
				"meta.id":           obj.Id,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Build finished",
			}},
		)
	})
}

func waitState(sl softlayer.SoftLayer_Virtual_Guest_Service, id int, state string) error {
	timeout := time.After(time.Minute * 5)
	ticker := time.NewTicker(time.Second * 10)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			s, err := sl.GetPowerState(id)
			if err != nil {
				return err
			}

			if strings.ToLower(strings.TrimSpace(s.KeyName)) ==
				strings.ToLower(strings.TrimSpace(state)) {
				return nil
			}
		case <-timeout:
			return errors.New("timeout while waiting for state")
		}
	}

}
