package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/packer"
	"net/url"
	"strconv"
	"time"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type Event struct {
	Status string `json:"status" mapstructure:"status"`
	Event  struct {
		Id           int    `json:"id" mapstructure:"id"`
		ActionStatus string `json:"action_status" mapstructure:"action_status"`
		DropletID    int    `json:"droplet_id" mapstructure:"droplet_id"`
		EventTypeID  int    `json:"event_type_id" mapstructure:"event_type_id"`
		Percentage   string `json:"percentage" mapstructure:"percentage"`
	} `json:"event" mapstructure:"event"`
}

type DropletInfo struct {
	Status  string `json:"status" mapstructure:"status"`
	Droplet struct {
		Id       int    `json:"id" mapstructure:"id"`
		Hostname string `json:"hostname" mapstructure:"hostname"`
		ImageId  int    `json:"image_id" mapstructure:"image_id"`
		SizeId   int    `json:"size_id" mapstructure:"size_id"`
		EventId  int    `json:"event_id" mapstructure:"event_id"`
	} `json:"droplet" mapstructure:"droplet"`
}

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

func (d *DigitalOcean) Build() (err error) {
	snapshotName := "koding-" + strconv.FormatInt(time.Now().UTC().Unix(), 10)
	d.Builder.SnapshotName = snapshotName

	data, err := templateData(d.Builder)
	if err != nil {
		return err
	}

	provider := &packer.Provider{
		BuildName: "digitalocean",
		Data:      data,
	}

	// this is basically a "packer build template.json"
	if err := provider.Build(); err != nil {
		return err
	}

	// after creating the image go and get it
	images, err := d.MyImages()
	if err != nil {
		return err
	}

	var image digitalocean.Image
	for _, i := range images {
		if i.Name == snapshotName {
			image = i
		}
	}

	if image.Id == 0 {
		return fmt.Errorf("Image %s is not available in Digital Ocean", snapshotName)
	}

	// now create a the machine based on our created image
	dropletInfo, err := d.CreateDroplet("arslan", image.Id)
	if err != nil {
		return err
	}

	// Now we wait until it's ready, it takes ann 50-70 seconds to finish, but
	// we also add a timeout to not let stuck it here.
	for {
		select {
		case <-time.After(time.Minute * 5):
			return errors.New("Timeout from DigitalOcean. droplet couldn't be created")
		case <-time.Tick(3 * time.Second):
			e, _ := d.CheckEvent(dropletInfo.Droplet.EventId)
			if e.Event.ActionStatus == "done" {
				return nil
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

func (d *DigitalOcean) Start(id string) error {
	path := fmt.Sprintf("droplets/%v/power_on", id)
	resp, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return err
	}

	fmt.Printf("start: resp %+v\n", resp)

	return nil
}

func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
