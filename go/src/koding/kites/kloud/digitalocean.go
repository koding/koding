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
		fmt.Printf("i %+v\n", i)
		if i.Name == snapshotName {
			image = i
		}
	}

	if image.Id == 0 {
		return fmt.Errorf("Image %s is not available in Digital Ocean", snapshotName)
	}

	// now create a the machine based on our created image
	dropletId, err := d.Client.CreateDroplet(
		"arslan",         // custom droplet name, must be formatted by hostname rules
		d.Builder.Size,   // size name
		image.Name,       // image name
		d.Builder.Region, // region name
		0,                // ssh key ID, we don't use any
		d.Builder.PrivateNetworking, // private networking
	)
	if err != nil {
		return err
	}

	fmt.Printf("success! dropletID %+v\n", dropletId)
	return nil

	// return provider.Build()
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

func (d *DigitalOcean) Start() error   { return nil }
func (d *DigitalOcean) Stop() error    { return nil }
func (d *DigitalOcean) Restart() error { return nil }
func (d *DigitalOcean) Destroy() error { return nil }
