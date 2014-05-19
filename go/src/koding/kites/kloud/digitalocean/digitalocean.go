package digitalocean

import (
	"errors"
	"fmt"
	"koding/kites/kloud/klientprovisioner"
	"koding/kites/kloud/packer"
	"koding/kites/kloud/utils"
	"net/url"
	"strconv"
	"time"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type DigitalOcean struct {
	Client *digitalocean.DigitalOceanClient
	Name   string

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

func (d *DigitalOcean) Build(raws ...interface{}) (interface{}, error) {
	if len(raws) != 2 {
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

	// needed because this is passed as `data` to packer.Provider
	d.Builder.SnapshotName = snapshotName

	var image digitalocean.Image
	var err error

	// check if snapshot image does exist, if not create a new one.
	image, err = d.Image(snapshotName)
	if err != nil {
		image, err = d.CreateImage()
		if err != nil {
			return nil, err
		}
	}

	// now create a the machine based on our created image
	dropletInfo, err := d.CreateDroplet(dropletName, image.Id)
	if err != nil {
		return nil, err
	}

	// Now we wait until it's ready, it takes ann 50-70 seconds to finish, but
	// we also add a timeout to not let stuck it here.
	for {
		select {
		case <-time.After(time.Minute * 5):
			return nil, errors.New("Timeout from DigitalOcean. droplet couldn't be created")
		case <-time.Tick(3 * time.Second):
			e, _ := d.CheckEvent(dropletInfo.Droplet.EventId)
			if e.Event.ActionStatus == "done" {
				return d.Info(dropletInfo.Droplet.Id)
			}
		}
	}
}

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

// CreateDroplet creates a new droplet with a hostname and the given image_id
func (d *DigitalOcean) CreateDroplet(hostname string, image_id uint) (*DropletInfo, error) {
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

func (d *DigitalOcean) Image(snapshotName string) (digitalocean.Image, error) {
	return d.Client.Image(snapshotName)
}

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

func (d *DigitalOcean) Stop(raws ...interface{}) error {
	if len(raws) == 0 {
		return errors.New("zero arguments are passed")
	}

	var dropletId uint
	if dropletId = utils.ToUint(raws[0]); dropletId == 0 {
		return fmt.Errorf("malformed data received %v. droplet Id must be an int.", raws[0])
	}

	return d.Client.ShutdownDroplet(dropletId)
}

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

func (d *DigitalOcean) DestroyImage(imageId uint) error {
	return d.Client.DestroyImage(imageId)
}

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

func (d *DigitalOcean) CreateSnapshot(dropletId uint, name string) error {
	return d.Client.CreateSnapshot(dropletId, name)
}

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
