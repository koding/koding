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

	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

const ProviderName = "digitalocean"

type pushFunc func(string, int)

// DigitalOcean is responsible of creating/controlling and handling one single
// Digital Ocean machine.
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

// WaitUntilReady checks the given state for the eventID and returns nil if the
// state has been reached. It returns an error if the given timeout has been
// reached, if another generic error is produced or if the event status is of
// type "ERROR".
func (d *DigitalOcean) WaitUntilReady(eventId, from, to int, push pushFunc) error {
	for {
		select {
		case <-time.After(time.Minute):
			return errors.New("Timeout while waiting for droplet to become ready")
		case <-time.Tick(3 * time.Second):
			if push != nil {
				push("Waiting for droplet to be ready", from)
			}

			event, err := d.CheckEvent(eventId)
			if err != nil {
				return err
			}

			if event.Event.ActionStatus == "done" {
				push("Waiting is done. Got a successfull result.", from)
				return nil
			}

			// the next steps percentage is 60, fake it until we got there
			if from < to {
				from += 2
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

// Destroyimage destroys an image for the given imageID.
func (d *DigitalOcean) DestroyImage(imageId uint) error {
	return d.Client.DestroyImage(imageId)
}

func (d *DigitalOcean) Regions() ([]digitalocean.Region, error) {
	return d.Client.Regions()
}

func (d *DigitalOcean) DestroyDroplet(dropletId uint) error {
	path := fmt.Sprintf("droplets/%v/destroy", dropletId)
	_, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	return err
}

// CreateSnapshot cretes a new snapshot with the name from the given droplet Id.
func (d *DigitalOcean) CreateSnapshot(dropletId uint, name string) error {
	return d.Client.CreateSnapshot(dropletId, name)
}

func (d *DigitalOcean) DropletInfo(dropletId uint) (*Droplet, error) {
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

	return &result, err
}

func (d *DigitalOcean) DropletId() (uint, error) {
	if d.Builder.DropletId == "" {
		return 0, errors.New("dropletId is not available")
	}

	dropletId := utils.ToUint(d.Builder.DropletId)
	if dropletId == 0 {
		return 0, fmt.Errorf("malformed data received %v. droplet Id must be an int.", d.Builder.DropletId)
	}

	return dropletId, nil
}
