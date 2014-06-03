package digitalocean

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klientprovisioner"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"koding/kites/kloud/packer"
	"koding/kites/kloud/sshutil"
	"koding/kites/kloud/utils"
	"net/url"
	"strconv"
	"time"

	klientprotocol "koding/kites/klient/protocol"

	kiteprotocol "github.com/koding/kite/protocol"
	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

const ProviderName = "digitalocean"

type DigitalOcean struct {
	Client   *digitalocean.DigitalOceanClient
	Log      logging.Logger
	SignFunc func(string) (string, string, error)

	Creds struct {
		ClientID string `mapstructure:"clientId"`
		APIKey   string `mapstructure:"apiKey"`
	}

	Builder struct {
		DropletId   string `mapstructure:"instanceId"`
		DropletName string `mapstructure:"droplet_name" packer:"droplet_name"`

		Type     string `mapstructure:"type" packer:"type"`
		ClientID string `mapstructure:"client_id" packer:"client_id"`
		APIKey   string `mapstructure:"api_key" packer:"api_key"`

		RegionID uint `mapstructure:"region_id" packer:"region_id"`
		SizeID   uint `mapstructure:"size_id" packer:"size_id"`
		ImageID  uint `mapstructure:"image_id" packer:"image_id"`

		Region string `mapstructure:"region" packer:"region"`
		Size   string `mapstructure:"size" packer:"size"`
		Image  string `mapstructure:"image" packer:"image"`

		PrivateNetworking bool   `mapstructure:"private_networking" packer:"private_networking"`
		SnapshotName      string `mapstructure:"snapshot_name" packer:"snapshot_name"`
		SSHUsername       string `mapstructure:"ssh_username" packer:"ssh_username"`
		SSHPort           uint   `mapstructure:"ssh_port" packer:"ssh_port"`

		RawSSHTimeout   string `mapstructure:"ssh_timeout"`
		RawStateTimeout string `mapstructure:"state_timeout"`
	}
}

func (d *DigitalOcean) Name() string {
	return ProviderName
}

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

	// push logs and pushes each step to the eventer
	push := func(msg string, percentage int) {
		d.Log.Debug("[machineId: '%s': username: '%s' dropletName: '%s' snapshotName: '%s'] - %s",
			opts.MachineId, opts.Username, opts.InstanceName, opts.ImageName, msg)

		opts.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     machinestate.Building,
			Percentage: percentage,
		})
	}

	// needed because this is passed as `data` to packer.Provider
	d.Builder.SnapshotName = snapshotName

	var image digitalocean.Image

	// check if snapshot image does exist, if not create a new one.
	push(fmt.Sprintf("Fetching image %s", snapshotName), 10)
	image, err = d.Image(snapshotName)
	if err != nil {
		d.Log.Info("Image %s does not exist, creating a new one", snapshotName)
		image, err = d.CreateImage()
		if err != nil {
			return nil, err
		}
	}

	// create temporary key to deploy user based key
	push(fmt.Sprintf("Creating temporary ssh key"), 15)

	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// The name of the public key on DO
	name := fmt.Sprintf("koding-%s", time.Now().UTC().UnixNano())
	keyId, err := d.CreateKey(name, publicKey)
	if err != nil {
		return nil, err
	}

	defer func() {
		push(fmt.Sprintf("Destroying droplet key"), 95)
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

	// Now we wait until it's ready, it takes approx. 50-70 seconds to finish,
	// but we also add a timeout  of five minutes to not let stuck it there
	// forever.
	tickFunc := func() error {
		n := 25
		for {
			select {
			case <-time.After(time.Minute * 5):
				return fmt.Errorf("Timeout while waiting to for droplet to become '%s'", "done")
			case <-time.Tick(3 * time.Second):
				push(fmt.Sprintf("Waiting for droplet to be ready ..."), n)
				event, err := d.CheckEvent(dropletInfo.Droplet.EventId)
				if err != nil {
					return err
				}

				if event.Event.ActionStatus == "done" {
					return nil
				}

				// the next steps percentage is 60, fake it until we got there
				if n < 59 {
					n += 2
				}
			}
		}
	}

	if err := tickFunc(); err != nil {
		return nil, err
	}

	// our droplet has now an IP adress, get it
	push(fmt.Sprintf("Getting info about droplet"), 60)
	info, err := d.Info(dropletInfo.Droplet.Id)
	if err != nil {
		return nil, err
	}
	dropInfo := info.(Droplet)

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
	kiteKey, kiteId, err := d.SignFunc(opts.Username)
	if err != nil {
		return nil, err
	}
	push(fmt.Sprintf("Kite key created for id %s", kiteId), 75)

	// for debugging, remove it later ...
	push(fmt.Sprintf("Writing kite key to temporary file (kite.key)"), 75)
	if err := ioutil.WriteFile("kite.key", []byte(kiteKey), 0400); err != nil {
		d.Log.Info("couldn't write temporary kite file", err)
	}

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

// CheckEvent checks the given eventID and returns back the result. It's useful
// for checking the status of an event. Usually it's called in a for/select
// statement and get polled.
func (d *DigitalOcean) CheckEvent(eventId int) (*Event, error) {
	path := fmt.Sprintf("events/%d", eventId)

	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return nil, err
	}

	event := &Event{}
	if err := mapstructure.Decode(body, event); err != nil {
		return nil, err
	}

	return event, nil
}

// WaitForState checks the given state for the eventID and returns nil if the
// state has been reached. It returns an error if the given timeout has been
// reached, if another generic error is produced or if the event status is of
// type "ERROR".
func (d *DigitalOcean) WaitForState(eventId int, desiredState string, timeout time.Duration) error {
	for {
		select {
		case <-time.After(timeout):
			return fmt.Errorf("Timeout while waiting to for droplet to become '%s'", desiredState)
		case <-time.Tick(3 * time.Second):
			event, err := d.CheckEvent(eventId)
			if err != nil {
				return err
			}

			if event.Event.ActionStatus == desiredState {
				return nil
			}
		}
	}
}

// CreateKey creates a new ssh key with the given name and the associated
// public key. It returns a unique id that is associated with the given
// publicKey. This id is used to show, edit or delete the key.
func (d *DigitalOcean) CreateKey(name, publicKey string) (uint, error) {
	return d.Client.CreateKey(name, publicKey)
}

// DestroyKey removes the ssh key that is associated with the given id.
func (d *DigitalOcean) DestroyKey(id uint) error {
	return d.Client.DestroyKey(id)
}

// CreateImage creates an image using Packer. It uses digitalocean.Builder
// data. It returns the image info.
func (d *DigitalOcean) CreateImage() (digitalocean.Image, error) {
	data, err := utils.TemplateData(d.Builder, klientprovisioner.RawData)
	if err != nil {
		return digitalocean.Image{}, err
	}

	provider := &packer.Provider{
		BuildName: "digitalocean",
		Data:      data,
	}

	// this is basically a "packer build template.json"
	if err := provider.Build(); err != nil {
		return digitalocean.Image{}, err
	}

	// return the image result
	return d.Image(d.Builder.SnapshotName)
}

// CreateDroplet creates a new droplet with a hostname, key and image_id. It
// returns back the dropletInfo.
func (d *DigitalOcean) CreateDroplet(hostname string, keyId, image_id uint) (*DropletInfo, error) {
	params := url.Values{}
	params.Set("name", hostname)

	found_size, err := d.Client.Size(d.Builder.Size)
	if err != nil {
		return nil, fmt.Errorf("Invalid size or lookup failure: '%s': %s", d.Builder.Size, err)
	}

	found_region, err := d.Client.Region(d.Builder.Region)
	if err != nil {
		return nil, fmt.Errorf("Invalid region or lookup failure: '%s': %s", d.Builder.Region, err)
	}

	params.Set("size_slug", found_size.Slug)
	params.Set("image_id", strconv.Itoa(int(image_id)))
	params.Set("region_slug", found_region.Slug)
	params.Set("ssh_key_ids", fmt.Sprintf("%v", keyId))
	params.Set("private_networking", fmt.Sprintf("%v", d.Builder.PrivateNetworking))

	body, err := digitalocean.NewRequest(*d.Client, "droplets/new", params)
	if err != nil {
		return nil, err
	}

	info := &DropletInfo{}
	if err := mapstructure.Decode(body, info); err != nil {
		return nil, err
	}

	return info, nil
}

// Droplets returns a slice of all Droplets.
func (d *DigitalOcean) Droplets() ([]Droplet, error) {
	resp, err := digitalocean.NewRequest(*d.Client, "droplets", url.Values{})
	if err != nil {
		return nil, err
	}

	var result DropletsResp
	if err := mapstructure.Decode(resp, &result); err != nil {
		return nil, err
	}

	return result.Droplets, nil
}

// Image returns a single image based on the given snaphot name, slug or id. It
// checks for each occurency and returns for the first match.
func (d *DigitalOcean) Image(slug_or_name_or_id string) (digitalocean.Image, error) {
	return d.Client.Image(slug_or_name_or_id)
}

// MyImages returns a slice of all personal images.
func (d *DigitalOcean) MyImages() ([]digitalocean.Image, error) {
	v := url.Values{}
	v.Set("filter", "my_images")

	resp, err := digitalocean.NewRequest(*d.Client, "images", v)
	if err != nil {
		return nil, err
	}

	var result digitalocean.ImagesResp
	if err := mapstructure.Decode(resp, &result); err != nil {
		return nil, err
	}

	return result.Images, nil
}

// Start starts the machine for the given dropletID
func (d *DigitalOcean) Start(raws ...interface{}) error {
	dropletId, err := d.DropletId(raws...)
	if err != nil {
		return err
	}

	path := fmt.Sprintf("droplets/%v/power_on", dropletId)
	_, err = digitalocean.NewRequest(*d.Client, path, url.Values{})
	return err
}

// Stop stops the machine for the given dropletID
func (d *DigitalOcean) Stop(raws ...interface{}) error {
	dropletId, err := d.DropletId(raws...)
	if err != nil {
		return err
	}

	err = d.Client.PowerOffDroplet(dropletId)
	if err != nil {
		return err
	}

	return nil
}

// Restart restart the machine for the given dropletID
func (d *DigitalOcean) Restart(raws ...interface{}) error {
	dropletId, err := d.DropletId(raws...)
	if err != nil {
		return err
	}

	path := fmt.Sprintf("droplets/%v/reboot", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return fmt.Errorf("restart malformed data %v", body)
	}

	if err := d.WaitForState(int(eventId), "done", time.Minute); err != nil {
		return err
	}

	return nil
}

// Destroyimage destroys an image for the given imageID.
func (d *DigitalOcean) DestroyImage(imageId uint) error {
	return d.Client.DestroyImage(imageId)
}

// Destroy destroys the machine with the given droplet ID.
func (d *DigitalOcean) Destroy(raws ...interface{}) error {
	dropletId, err := d.DropletId(raws...)
	if err != nil {
		return err
	}

	return d.Client.DestroyDroplet(dropletId)
}

// CreateSnapshot cretes a new snapshot with the name from the given droplet Id.
func (d *DigitalOcean) CreateSnapshot(dropletId uint, name string) error {
	return d.Client.CreateSnapshot(dropletId, name)
}

// Info returns all information about the given droplet info.
func (d *DigitalOcean) Info(raws ...interface{}) (interface{}, error) {
	dropletId, err := d.DropletId(raws...)
	if err != nil {
		return nil, err
	}

	path := fmt.Sprintf("droplets/%v", dropletId)
	resp, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return nil, err
	}

	droplet, ok := resp["droplet"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("malformed data received %v", resp)
	}

	var result Droplet
	if err := mapstructure.Decode(droplet, &result); err != nil {
		return nil, err
	}

	return result, err
}

func (d *DigitalOcean) DropletId(raws ...interface{}) (uint, error) {
	var rawData interface{}

	if len(raws) == 1 {
		rawData = raws[0]
	} else if d.Builder.DropletId != "" {
		rawData = d.Builder.DropletId
	} else {
		return 0, errors.New("dropletId is not available")
	}

	dropletId := utils.ToUint(rawData)
	if dropletId == 0 {
		return 0, fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	return dropletId, nil
}
