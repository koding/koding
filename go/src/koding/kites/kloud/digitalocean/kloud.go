package digitalocean

import (
	"errors"
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"koding/kites/kloud/sshutil"
	"net/url"
	"strconv"
	"time"

	klientprotocol "koding/kites/klient/protocol"

	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

// Prepare prepares the state for upcoming methods like Build/etc.. It's needs to
// be called before every other method call once. Raws contains the credentials
// as a map[string]interface{} format.
func (d *DigitalOcean) Prepare(raws ...interface{}) (err error) {
	if len(raws) != 2 {
		return errors.New("need at least two arguments")
	}

	// Credentials
	if err := mapstructure.Decode(raws[0], &d.Creds); err != nil {
		return err
	}

	// Builder data
	if err := mapstructure.Decode(raws[1], &d.Builder); err != nil {
		return err
	}

	if d.Creds.ClientID == "" {
		return errors.New("credentials client_id is empty")
	}

	if d.Creds.APIKey == "" {
		return errors.New("credentials api_key is empty")
	}

	d.Builder.ClientID = d.Creds.ClientID
	d.Builder.APIKey = d.Creds.APIKey

	d.Client = digitalocean.DigitalOceanClient{}.New(d.Creds.ClientID, d.Creds.APIKey)

	// authenticate credentials with a simple call
	// TODO: cache gor a given clientID and apiKey
	d.Log.Debug("Testing authentication with a simple /regions call")
	_, err = d.Regions()
	if err != nil {
		return errors.New("authentication with DigitalOcean failed.")
	}

	return nil
}

// Build is building an image and creates a droplet based on that image. If the
// given snapshot/image exist it directly skips to creating the droplet. It
// acceps two string arguments, first one is the snapshotname, second one is
// the dropletName.
func (d *DigitalOcean) Build(opts *protocol.MachineOptions) (p *protocol.BuildResponse, err error) {
	if opts.ImageName == "" {
		return nil, errors.New("snapshotName is empty")
	}
	snapshotName := opts.ImageName

	if opts.InstanceName == "" {
		return nil, errors.New("dropletName is empty")
	}
	dropletName := opts.InstanceName

	if opts.Username == "" {
		return nil, errors.New("username is empty")
	}

	if opts.Eventer == nil {
		return nil, errors.New("Eventer is not defined.")
	}

	push := d.pusher(opts, machinestate.Building)

	// needed because this is passed as `data` to packer.Provider
	d.Builder.SnapshotName = snapshotName

	var image digitalocean.Image

	// check if snapshot image does exist, if not create a new one.
	push(fmt.Sprintf("Fetching image %s", snapshotName), 10)
	image, err = d.Image(snapshotName)
	if err != nil {
		push(fmt.Sprintf("Image %s does not exist, creating a new one", snapshotName), 12)
		image, err = d.CreateImage()
		if err != nil {
			return nil, err
		}

		defer func() {
			// return value of latest err, if there is no error just return lazily
			if err == nil {
				return
			}

			push("Destroying image", 95)
			err := d.DestroyImage(image.Id)
			if err != nil {
				curlstr := fmt.Sprintf("curl '%v/images/%d/destroy?client_id=%v&api_key=%v'",
					digitalocean.DIGITALOCEAN_API_URL, image.Id, d.Creds.ClientID, d.Creds.APIKey)

				push(fmt.Sprintf("Error cleaning up droplet. Please delete the droplet manually: %v", curlstr), 95)
			}
		}()
	}

	// create temporary key to deploy user based key
	push(fmt.Sprintf("Creating temporary ssh key"), 15)
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// The name of the public key on DO
	name := fmt.Sprintf("koding-%d", time.Now().UTC().UnixNano())
	d.Log.Debug("Creating key with name '%s'", name)
	keyId, err := d.CreateKey(name, publicKey)
	if err != nil {
		return nil, err
	}

	defer func() {
		push("Destroying temporary droplet key", 95)
		err := d.DestroyKey(keyId) // remove after we are done
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/ssh_keys/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, keyId, d.Creds.ClientID, d.Creds.APIKey)

			push(fmt.Sprintf("Error cleaning up ssh key. Please delete the key manually: %v", curlstr), 95)
		}
	}()

	// now create a the machine based on our created image
	push(fmt.Sprintf("Creating droplet %s", dropletName), 20)
	dropletInfo, err := d.CreateDroplet(dropletName, keyId, image.Id)
	if err != nil {
		return nil, err
	}
	d.Builder.DropletId = strconv.Itoa(dropletInfo.Droplet.Id)

	defer func() {
		// return value of latest err, if there is no error just return lazily
		if err == nil {
			return
		}

		push("Destroying droplet", 95)
		err := d.DestroyDroplet(uint(dropletInfo.Droplet.Id))
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/droplets/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, dropletInfo.Droplet.Id, d.Creds.ClientID, d.Creds.APIKey)

			push(fmt.Sprintf("Error cleaning up droplet. Please delete the droplet manually: %v", curlstr), 95)
		}
	}()

	// Now we wait until it's ready, it takes approx. 50-70 seconds to finish,
	// but we also add a timeout  of five minutes to not let stuck it there
	// forever.
	if err := d.WaitUntilReady(dropletInfo.Droplet.EventId, 25, 59, push); err != nil {
		return nil, err
	}

	// our droplet has now an IP adress, get it
	push(fmt.Sprintf("Getting info about droplet"), 60)

	dropInfo, err := d.DropletStatus(uint(dropletInfo.Droplet.Id))
	if err != nil {
		return nil, err
	}

	sshAddress := dropInfo.IpAddress + ":22"
	sshConfig, err := sshutil.SshConfig(privateKey)
	if err != nil {
		return nil, err
	}

	push(fmt.Sprintf("Connecting to ssh %s", sshAddress), 65)
	client, err := sshutil.ConnectSSH(sshAddress, sshConfig)
	if err != nil {
		return nil, err
	}
	defer client.Close()

	// generate kite key specific for the user
	push("Creating kite.key", 70)
	kiteKey, kiteId, err := d.SignFunc(opts.Username)
	if err != nil {
		return nil, err
	}
	push(fmt.Sprintf("Kite key created for id %s", kiteId), 75)

	// for debugging, remove it later ...
	push(fmt.Sprintf("Writing kite key to temporary file (kite.key)"), 75)
	// DEBUG
	// if err := ioutil.WriteFile("kite.key", []byte(kiteKey), 0400); err != nil {
	// 	d.Log.Info("couldn't write temporary kite file", err)
	// }

	keyPath := "/opt/kite/klient/key/kite.key"

	push(fmt.Sprintf("Copying remote kite key %s", keyPath), 85)
	remoteFile, err := client.Create(keyPath)
	if err != nil {
		return nil, err
	}

	_, err = remoteFile.Write([]byte(kiteKey))
	if err != nil {
		return nil, err
	}

	push(fmt.Sprintf("Starting klient on remote machine"), 90)
	if err := client.StartCommand("service klient start"); err != nil {
		return nil, err
	}

	// arslan/public-host/klient/0.0.1/unknown/testkloud-1401755272229370184-0/393ff626-8fa5-4713-648c-4a51604f98c6
	klient := kiteprotocol.Kite{
		Username:    opts.Username, // kite.key is signed for this user
		ID:          kiteId,        // id is generated by ourself
		Hostname:    dropletName,   // hostname is the dropletName
		Name:        klientprotocol.Name,
		Environment: klientprotocol.Environment,
		Region:      klientprotocol.Region,
		Version:     klientprotocol.Version,
	}

	return &protocol.BuildResponse{
		QueryString:  klient.String(),
		IpAddress:    dropInfo.IpAddress,
		InstanceName: dropInfo.Name,
		InstanceId:   dropInfo.Id,
	}, nil
}

// Start starts the machine for the given dropletID
func (d *DigitalOcean) Start(opts *protocol.MachineOptions) error {
	push := d.pusher(opts, machinestate.Starting)
	dropletId, err := d.DropletId()
	if err != nil {
		return err
	}

	push("Starting machine", 10)

	path := fmt.Sprintf("droplets/%v/power_on", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	push("Start message is being sent, waiting.", 30)

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return fmt.Errorf("restart malformed data %v", body)
	}

	return d.WaitUntilReady(int(eventId), 30, 80, push)
}

// Stop stops the machine for the given dropletID
func (d *DigitalOcean) Stop(opts *protocol.MachineOptions) error {
	push := d.pusher(opts, machinestate.Stopping)
	dropletId, err := d.DropletId()
	if err != nil {
		return err
	}

	push("Stopping machine", 10)

	path := fmt.Sprintf("droplets/%v/shutdown", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	push("Stop message is being sent, waiting.", 30)

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return fmt.Errorf("restart malformed data %v", body)
	}

	return d.WaitUntilReady(int(eventId), 30, 80, push)
}

// Restart restart the machine for the given dropletID
func (d *DigitalOcean) Restart(opts *protocol.MachineOptions) error {
	push := d.pusher(opts, machinestate.Rebooting)
	dropletId, err := d.DropletId()
	if err != nil {
		return err
	}

	push("Rebooting machine", 10)

	path := fmt.Sprintf("droplets/%v/reboot", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	push("Reboot message is being sent, waiting.", 30)

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return fmt.Errorf("restart malformed data %v", body)
	}

	return d.WaitUntilReady(int(eventId), 30, 80, push)
}

// Destroy destroys the machine with the given droplet ID.
func (d *DigitalOcean) Destroy(opts *protocol.MachineOptions) error {
	push := d.pusher(opts, machinestate.Terminating)
	dropletId, err := d.DropletId()
	if err != nil {
		return err
	}

	push("Terminating machine", 10)

	path := fmt.Sprintf("droplets/%v/destroy", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	push("Terminating message is being sent, waiting.", 30)

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return fmt.Errorf("restart malformed data %v", body)
	}

	return d.WaitUntilReady(int(eventId), 50, 80, push)
}

// Info returns all information about the given droplet info.
func (d *DigitalOcean) Info(opts *protocol.MachineOptions) (*protocol.InfoResponse, error) {
	dropletId, err := d.DropletId()
	if err != nil {
		return nil, err
	}

	droplet, err := d.DropletStatus(dropletId)
	if err != nil {
		return nil, err
	}

	if statusToState(droplet.Status) == machinestate.Unknown {
		d.Log.Warning("Unknown digitalocean status: %s. This needs to be fixed.", droplet.Status)
	}

	return &protocol.InfoResponse{
		State: statusToState(droplet.Status),
	}, nil

}

// statusToState converts a digitalocean status to a sensible
// machinestate.State format
func statusToState(status string) machinestate.State {
	switch status {
	case "active":
		return machinestate.Running
	case "off":
		return machinestate.Stopped
	case "new":
		return machinestate.Building
	default:
		return machinestate.Unknown
	}

}

func (d *DigitalOcean) pusher(opts *protocol.MachineOptions, state machinestate.State) pushFunc {
	return func(msg string, percentage int) {
		d.Log.Info("[machineId: '%s': username: '%s' dropletName: '%s' snapshotName: '%s'] - %s",
			opts.MachineId, opts.Username, opts.InstanceName, opts.ImageName, msg)

		opts.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     state,
			Percentage: percentage,
		})
	}
}
