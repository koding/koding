package digitalocean

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/klientprovisioner"
	"koding/kites/kloud/packer"
	"koding/kites/kloud/sshutil"
	"koding/kites/kloud/utils"
	"net/url"
	"strconv"
	"time"

	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type DigitalOcean struct {
	Client *digitalocean.DigitalOceanClient
	Name   string
	Log    logging.Logger

	Creds struct {
		ClientID string `mapstructure:"client_id"`
		APIKey   string `mapstructure:"api_key"`
	}

	Builder struct {
		Type     string `mapstructure:"type"`
		ClientID string `mapstructure:"client_id"`
		APIKey   string `mapstructure:"api_key"`

		RegionID uint `mapstructure:"region_id"`
		SizeID   uint `mapstructure:"size_id"`
		ImageID  uint `mapstructure:"image_id"`

		Region string `mapstructure:"region"`
		Size   string `mapstructure:"size"`
		Image  string `mapstructure:"image"`

		PrivateNetworking bool   `mapstructure:"private_networking"`
		SnapshotName      string `mapstructure:"snapshot_name"`
		DropletName       string `mapstructure:"droplet_name"`
		SSHUsername       string `mapstructure:"ssh_username"`
		SSHPort           uint   `mapstructure:"ssh_port"`

		RawSSHTimeout   string `mapstructure:"ssh_timeout"`
		RawStateTimeout string `mapstructure:"state_timeout"`
	}
}

// Setup prepares the state for upcoming methods like Start/Stop/etc.. It's
// needs to be called before every other method call once. Raws contains the
// credentials as a map[string]interface{} format.
func (d *DigitalOcean) Setup(raws ...interface{}) (err error) {
	d.Name = "digitalocean"
	if len(raws) != 1 {
		return errors.New("need at least two arguments")
	}

	// Credentials
	if err := mapstructure.Decode(raws[0], &d.Creds); err != nil {
		return err
	}

	if d.Creds.ClientID == "" {
		return errors.New("credentials client_id is empty")
	}

	if d.Creds.APIKey == "" {
		return errors.New("credentials api_key is empty")
	}

	d.Client = digitalocean.DigitalOceanClient{}.New(d.Creds.ClientID, d.Creds.APIKey)
	return nil
}

// Setup prepares the state for upcoming methods like Build/etc.. It's needs to
// be called before every other method call once. Raws contains the credentials
// as a map[string]interface{} format.
func (d *DigitalOcean) Prepare(raws ...interface{}) (err error) {
	d.Name = "digitalocean"
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

	d.Client = digitalocean.DigitalOceanClient{}.New(d.Creds.ClientID, d.Creds.APIKey)
	return nil
}

// Build is building an image and creates a droplet based on that image. If the
// given snapshot/image exist it directly skips to creating the droplet. It
// acceps two string arguments, first one is the snapshotname, second one is
// the dropletName.
func (d *DigitalOcean) Build(raws ...interface{}) (interface{}, error) {
	if len(raws) != 3 {
		return nil, errors.New("need one argument. No snaphost name is provided")
	}

	snapshotName, ok := raws[0].(string)
	if !ok {
		return nil, fmt.Errorf("malformed data received %v. snapshot name must be a string", raws[0])
	}

	dropletName, ok := raws[1].(string)
	if !ok {
		return nil, fmt.Errorf("malformed data received %v. droplet name must be a string", raws[0])
	}

	signFunc, ok := raws[2].(func() (string, string, error))
	if !ok {
		return nil, fmt.Errorf("malformed data received %v. function signature must be func() (string,error)", raws[0])
	}

	// needed because this is passed as `data` to packer.Provider
	d.Builder.SnapshotName = snapshotName

	var image digitalocean.Image
	var err error

	// check if snapshot image does exist, if not create a new one.
	d.Log.Info("Fetching image %s", snapshotName)
	image, err = d.Image(snapshotName)
	if err != nil {
		d.Log.Info("Image %s does not exist, creating a new one", snapshotName)
		image, err = d.CreateImage()
		if err != nil {
			return nil, err
		}
	}

	// create temporary key to deploy user based key
	d.Log.Info("Creating temporary ssh key")
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
		d.Log.Info("Destroying droplet key")
		err := d.DestroyKey(keyId) // remove after we are done
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/ssh_keys/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, keyId, d.Creds.ClientID, d.Creds.APIKey)

			d.Log.Error("Error cleaning up ssh key. Please delete the key manually: %v", curlstr)
		}
	}()

	// now create a the machine based on our created image
	d.Log.Info("Creating droplet %s", dropletName)
	dropletInfo, err := d.CreateDroplet(dropletName, keyId, image.Id)
	if err != nil {
		return nil, err
	}

	// Now we wait until it's ready, it takes approx. 50-70 seconds to finish,
	// but we also add a timeout  of five minutes to not let stuck it there
	// forever.
	d.Log.Info("Waiting for droplet to be ready ...")
	err = d.WaitForState(dropletInfo.Droplet.EventId, "done", time.Minute*5)
	if err != nil {
		return nil, err
	}

	// our droplet has now an IP adress, get it
	d.Log.Info("Getting info about droplet")
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

	d.Log.Info("Connecting to ssh %s", sshAddress)
	client, err := sshutil.ConnectSSH(sshAddress, sshConfig)
	if err != nil {
		return nil, err
	}
	defer client.Close()

	// genereate kite key specific for the user
	kiteKey, kiteId, err := signFunc()
	if err != nil {
		return nil, err
	}
	d.Log.Info("Kite key created for id %s", kiteId)

	// for debugging, remove it later ...
	d.Log.Info("Writing kite key to temporary file (kite.key)")
	if err := ioutil.WriteFile("kite.key", []byte(kiteKey), 0400); err != nil {
		d.Log.Info("couldn't write temporary kite file", err)
	}

	keyPath := "/opt/kite/klient/key/kite.key"

	d.Log.Info("Copying remote kite key %s", keyPath)
	remoteFile, err := client.Create(keyPath)
	if err != nil {
		return nil, err
	}

	_, err = remoteFile.Write([]byte(kiteKey))
	if err != nil {
		return nil, err
	}

	d.Log.Info("Starting klient on remote machine")
	if err := client.StartCommand("service klient start"); err != nil {
		return nil, err
	}

	return dropInfo, nil
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
	if len(raws) == 0 {
		return errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	path := fmt.Sprintf("droplets/%v/power_on", dropletId)
	_, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	return err
}

// Stop stops the machine for the given dropletID
func (d *DigitalOcean) Stop(raws ...interface{}) error {
	if len(raws) == 0 {
		return errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	err := d.Client.PowerOffDroplet(dropletId)
	if err != nil {
		return err
	}

	return nil
}

// Restart restart the machine for the given dropletID
func (d *DigitalOcean) Restart(raws ...interface{}) error {
	if len(raws) == 0 {
		return errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	path := fmt.Sprintf("droplets/%v/reboot", dropletId)
	_, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	return err
}

// Destroyimage destroys an image for the given imageID.
func (d *DigitalOcean) DestroyImage(imageId uint) error {
	return d.Client.DestroyImage(imageId)
}

// Destroy destroys the machine with the given droplet ID.
func (d *DigitalOcean) Destroy(raws ...interface{}) error {
	if len(raws) == 0 {
		return errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	return d.Client.DestroyDroplet(dropletId)
}

// CreateSnapshot cretes a new snapshot with the name from the given droplet Id.
func (d *DigitalOcean) CreateSnapshot(dropletId uint, name string) error {
	return d.Client.CreateSnapshot(dropletId, name)
}

// Info returns all information about the given droplet info.
func (d *DigitalOcean) Info(raws ...interface{}) (interface{}, error) {
	if len(raws) == 0 {
		return nil, errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return nil, fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
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
