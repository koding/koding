package softlayer

import (
	"encoding/json"
	"errors"
	"strings"
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite/protocol"
	datatypes "github.com/maximilien/softlayer-go/data_types"
	"github.com/maximilien/softlayer-go/softlayer"
	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	// The script is located at go/src/koding/kites/kloud/provisioner.
	PostInstallScriptUri = "https://s3.amazonaws.com/koding-softlayer/softlayer-cloud-init.sh"

	// Only lookup images that have this tag
	DefaultTemplateTag = "koding-stable"
)

func (m *Machine) Build(ctx context.Context) (err error) {
	if err := modelhelper.ChangeMachineState(m.ObjectId, "Building started", machinestate.Building); err != nil {
		return err
	}

	latestState := m.State()
	defer func() {
		// if there is any error mark it as NotInitialized
		if err != nil {
			modelhelper.ChangeMachineState(m.ObjectId, "Machine is marked as "+latestState.String(), latestState)
		}
	}()

	keys, ok := publickeys.FromContext(ctx)
	if !ok {
		return errors.New("public keys are not available")
	}

	m.push("Generating and fetching build data", 10, machinestate.Building)

	m.Log.Debug("Creating the custom data")

	sshKeys := make([]string, len(m.User.SshKeys))
	for i, sshKey := range m.User.SshKeys {
		sshKeys[i] = sshKey.Key
	}
	// also append our own public key so we can use it ssh into the machine and debug it
	sshKeys = append(sshKeys, keys.PublicKey)

	kiteID := uuid.NewV4().String()

	cloudInitConfig := &userdata.CloudInitConfig{
		Username:           m.Username,
		Groups:             []string{"docker", "sudo"},
		UserSSHKeys:        sshKeys,
		Hostname:           m.Username, // no typo here. hostname = username
		KiteId:             kiteID,
		DisableEC2MetaData: true,
		KodingSetup:        true,
	}

	cloudInit, err := m.Session.Userdata.Create(cloudInitConfig)
	if err != nil {
		return err
	}

	userdata := struct {
		CloudInit []byte `json:"cloudInit,omitempty"`
	}{
		CloudInit: cloudInit,
	}
	// pass the values as a json. Our script will unmarshall and use it inside
	// the instance
	val, err := json.Marshal(&userdata)
	if err != nil {
		return err
	}

	m.Log.Debug("Custom data is created:")
	m.Log.Debug("%s", string(val))

	m.push("Initiating build process", 30, machinestate.Building)

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	imageID, err := m.lookupImage(DefaultTemplateTag, meta.Datacenter)
	if err != nil {
		return err
	}

	m.Meta["sourceImage"] = imageID

	//Create a template for the virtual guest (changing properties as needed)
	virtualGuestTemplate := datatypes.SoftLayer_Virtual_Guest_Template{
		Hostname:          m.Username,  // this is correct, we use the username as hostname
		Domain:            "koding.io", // this is just a placeholder
		StartCpus:         1,
		MaxMemory:         1024,
		Datacenter:        datatypes.Datacenter{Name: meta.Datacenter},
		HourlyBillingFlag: true,
		LocalDiskFlag:     true,
		BlockDeviceTemplateGroup: &datatypes.BlockDeviceTemplateGroup{
			GlobalIdentifier: imageID,
		},
		UserData:             []datatypes.UserData{{Value: string(val)}},
		PostInstallScriptUri: PostInstallScriptUri,
	}

	m.Log.Debug("Creating the server instance with following data: %+v", virtualGuestTemplate)

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

	m.push("Checking build process", 50, machinestate.Building)

	// wait until it's ready
	m.Log.Debug("Waiting for the state to be RUNNING (%d)", obj.Id)
	if err := waitState(svc, obj.Id, "RUNNING"); err != nil {
		return err
	}

	// get final information, such as public IP address and co
	obj, err = svc.GetObject(obj.Id)
	if err != nil {
		return err
	}

	m.Log.Debug("Final object:")
	m.Log.Debug("%+v", obj)

	m.QueryString = protocol.Kite{ID: kiteID}.String()
	m.IpAddress = obj.PrimaryIpAddress

	if err := m.addDomains(); err != nil {
		m.Log.Warning("couldn't add domains during build: %s", err)
	}

	m.push("Waiting for Koding Service Connector", 80, machinestate.Building)

	if !m.IsKlientReady() {
		return errors.New("klient is not ready")
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":         m.IpAddress,
				"queryString":       m.QueryString,
				"meta.id":           obj.Id,
				"meta.datacenter":   meta.Datacenter,
				"meta.sourceImage":  imageID,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Build finished",
			}},
		)
	})
}

func (m *Machine) lookupImage(tag, datacenter string) (globalID string, err error) {
	m.Log.Debug("Looking for a Koding Base Image with name=%q in datacenter=%q", tag, datacenter)

	filter := &sl.Filter{
		Tags: sl.Tags{
			"Name": tag,
		},
	}

	global, err := m.Session.SLClient.TemplatesByFilter(filter)
	if err != nil {
		return "", err
	}

	if regional := global.ByDatacenter(datacenter); len(regional) != 0 {
		if len(regional) > 1 {
			m.Log.Warning("more than one template found for tag=%q, datacener=%q - using latest", tag, datacenter)
		}
		return regional[0].GlobalID, nil
	}

	m.Log.Warning("no templates found for tag=%q, datacenter=%q - falling back to global", tag, datacenter)

	return global[0].GlobalID, nil
}

func waitState(sl softlayer.SoftLayer_Virtual_Guest_Service, id int, state string) error {
	timeout := time.After(time.Minute * 10)
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
