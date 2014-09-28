package api

import (
	"errors"
	"fmt"
	"net/url"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

// DigitalOcean is responsible of creating/controlling and handling one single
// Digital Ocean machine.
type DigitalOcean struct {
	Client *digitalocean.DigitalOceanClient

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

		// KeyName is used to deploy the machine with that particular key
		KeyName string `mapstructure:"key_name"`

		// PublicKey and PrivateKey is used to create a new key.
		PublicKey  string `mapstructure:"publicKey"`
		PrivateKey string `mapstructure:"privateKey"`

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

func New(credential, builder map[string]interface{}) (*DigitalOcean, error) {
	d := DigitalOcean{}

	// Credentials
	if err := mapstructure.Decode(credential, &d.Creds); err != nil {
		return nil, err
	}

	// Builder data
	if err := mapstructure.Decode(builder, &d.Builder); err != nil {
		return nil, err
	}

	if d.Creds.ClientID == "" {
		return nil, errors.New("credentials client_id is empty")
	}

	if d.Creds.APIKey == "" {
		return nil, errors.New("credentials api_key is empty")
	}

	d.Builder.ClientID = d.Creds.ClientID
	d.Builder.APIKey = d.Creds.APIKey

	d.Client = digitalocean.DigitalOceanClient{}.New(d.Creds.ClientID, d.Creds.APIKey)

	// authenticate credentials with a simple call
	_, err := d.Regions()
	if err != nil {
		return nil, errors.New("authentication with DigitalOcean failed.")
	}

	return &d, nil
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

func (d *DigitalOcean) Regions() ([]digitalocean.Region, error) {
	return d.Client.Regions()
}

// CreateSnapshot cretes a new snapshot with the name from the given droplet Id.
func (d *DigitalOcean) CreateSnapshot(dropletId uint, name string) error {
	return d.Client.CreateSnapshot(dropletId, name)
}

func (d *DigitalOcean) Rename(dropletId uint, newName string) (int, error) {
	params := url.Values{}
	params.Set("name", newName)

	path := fmt.Sprintf("droplets/%v/rename", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, params)
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("restart malformed data %v", body)
	}

	return int(eventId), nil
}

// Start starts the machine for the given dropletID
func (d *DigitalOcean) PowerOn(dropletId uint) (int, error) {
	path := fmt.Sprintf("droplets/%v/power_on", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("restart malformed data %v", body)
	}

	return int(eventId), nil
}

// Shutdown stops the machine for the given dropletID and returns the eventID
// back to track the event.
func (d *DigitalOcean) Shutdown(dropletId uint) (int, error) {
	path := fmt.Sprintf("droplets/%v/shutdown", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("restart malformed data %v", body)
	}

	return int(eventId), nil
}

// Reboot restart the machine for the given dropletID and returns the eventId
// back to track the event.
func (d *DigitalOcean) Reboot(dropletId uint) (int, error) {
	path := fmt.Sprintf("droplets/%v/reboot", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("restart malformed data %v", body)
	}

	return int(eventId), nil
}
