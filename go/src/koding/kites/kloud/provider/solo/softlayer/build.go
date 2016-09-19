package softlayer

import (
	"encoding/json"
	"errors"
	"strconv"
	"strings"
	"time"

	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite/protocol"
	datatypes "github.com/maximilien/softlayer-go/data_types"
	"github.com/satori/go.uuid"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	// The script is located at go/src/koding/kites/kloud/provisioner.
	PostInstallScriptUri = "https://koding-softlayer.s3.amazonaws.com/softlayer-cloud-init.sh"

	// Only lookup images that have this tag
	DefaultTemplateTag = "koding-stable"
)

func IsHostnameSyntaxError(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "The hostname and domain must be alphanumeric strings that may be separated by periods")
}

func (m *Machine) Build(ctx context.Context) error {
	return m.guardTransition(machinestate.Building, "Building started", ctx, m.build)
}

func (m *Machine) build(ctx context.Context) error {
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

	hostname := m.Username // using username as a hostname
	if _, err := strconv.Atoi(hostname); err == nil {
		// hostname cannot be a number, use m.Uid instead
		hostname = m.Uid
	}

	//Create a template for the virtual guest (changing properties as needed)
	virtualGuestTemplate := datatypes.SoftLayer_Virtual_Guest_Template{
		Hostname:          hostname,
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

	if meta.VlanID == 0 {
		meta.VlanID = m.findAvailableVlan(meta)
	}
	if meta.VlanID != 0 {
		m.Log.Debug("Assigning VLAN: %d", meta.VlanID)

		virtualGuestTemplate.PrimaryBackendNetworkComponent = &datatypes.PrimaryBackendNetworkComponent{
			NetworkVlan: datatypes.NetworkVlan{
				Id: meta.VlanID,
			},
		}
	} else {
		m.Log.Warning("unable to get koding VLAN; falling back to default")
	}

	m.Log.Debug("Creating the server instance with following data: %+v", virtualGuestTemplate)

	//Get the SoftLayer virtual guest service
	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}

	//Create the virtual guest with the service
	obj, err := svc.CreateObject(virtualGuestTemplate)
	if IsHostnameSyntaxError(err) {
		virtualGuestTemplate.Hostname = m.Uid // username can't be used as hostname, use uid instead
		obj, err = svc.CreateObject(virtualGuestTemplate)
	}
	if err != nil {
		return err
	}

	m.push("Checking build process", 50, machinestate.Building)

	// wait until it's ready
	m.Log.Debug("Waiting for the state to be RUNNING (%d)", obj.Id)
	if err := m.waitState(svc, obj.Id, "RUNNING", m.StateTimeout); err != nil {
		return err
	}

	// get final information, such as public IP address and co
	obj, err = svc.GetObject(obj.Id)
	if err != nil {
		return err
	}

	m.Log.Debug("Final object:")
	m.Log.Debug("%+v", obj)

	// Softlayer always converts all text to lower case, that's
	// why the "-machineid" or "-groupid" are not a typo.
	tags := map[string]string{
		"koding-user":      m.Username,
		"koding-env":       m.Session.Kite.Config.Environment,
		"koding-machineid": m.ObjectId.Hex(),
		"koding-domain":    m.Domain,
	}
	if len(m.Groups) != 0 {
		tags["koding-groupid"] = m.Groups[0].Id.Hex()
	}

	if err = m.Session.SLClient.InstanceSetTags(obj.Id, sl.Tags(tags)); err != nil {
		m.Log.Warning("couldn't set tags during build: %s", err)
	}

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
				"meta.vlanId":       meta.VlanID,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"domain":            m.Domain,
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

func (m *Machine) findAvailableVlan(meta *Meta) int {
	if meta.VlanID != 0 {
		return meta.VlanID
	}

	f := &sl.Filter{
		Datacenter: meta.Datacenter,
		Tags: sl.Tags{
			"koding-env": m.Session.Kite.Config.Environment,
		},
	}

	vlans, err := m.Session.SLClient.VlansByFilter(f)
	if err != nil {
		m.Log.Warning("failed querying for vlans with filter=%+v: %s", f, err)
		return 0
	}

	var available int
	for i, vlan := range vlans {
		capacity, err := strconv.ParseInt(vlan.Tags["koding-vlan-cap"], 10, 32)

		m.Log.Debug("checking vlan=%d (%d/%d)", vlan.ID, vlan.InstanceCount, capacity)

		// Arbitrary picked value - if vlan is has more than 20% capacity
		// we're using it. This check is here to help not to overassign
		// instances to vlan, e.g. when vlan is 249/250 and 10 concurrent requests
		// chooses this vlan.
		if err == nil && vlan.InstanceCount < int(0.8*float64(capacity)+0.5) {
			return vlan.ID
		}

		// Otherwise we pick the least crowded vlan.
		if vlans[available].InstanceCount > vlan.InstanceCount {
			available = i
		}
	}

	return vlans[available].ID
}
