package api

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type Snapshot struct {
	Id           int
	Name         string
	Slug         string
	Distribution string
}

type Droplet struct {
	Id               int        `json:"id" mapstructure:"id"`
	Name             string     `json:"name" mapstructure:"name"`
	ImageId          int        `json:"image_id" mapstructure:"image_id"`
	SizeId           int        `json:"size_id" mapstructure:"size_id"`
	RegionId         int        `json:"region_id" mapstructure:"region_id"`
	EventId          int        `json:"event_id" mapstructure:"event_id"`
	BackupsActive    bool       `json:"backups_active" mapstructure:"backups_active"`
	Backups          []string   `json:"backups" mapstructure:"backups"`
	Snapshots        []Snapshot `json:"snapshots" mapstructure:"snapshots"`
	IpAddress        string     `json:"ip_address" mapstructure:"ip_address"`
	PrivateIpAddress string     `json:"private_ip_address" mapstructure:"private_ip_address"`
	Locked           bool       `json:"locked" mapstructure:"locked"`
	Status           string     `json:"status" mapstructure:"status"`
	CreatedAt        string     `json:"created_at" mapstructure:"created_at"`
}

type Droplets []Droplet

func (d Droplets) Len() int {
	return len(d)
}

// Filter returns a new modified droplet list which only contains droplets with
// the given name.
func (d Droplets) Filter(name string) Droplets {
	filtered := make(Droplets, 0)

	for _, droplet := range d {
		if strings.Contains(droplet.Name, name) {
			filtered = append(filtered, droplet)
		}

	}

	return filtered
}

// Droplets returns a slice of all Droplets.
func (d *DigitalOcean) Droplets() (Droplets, error) {
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

// Destroy destroy the machine for the given dropletID and returns the eventId
// back to track the event.
func (d *DigitalOcean) DestroyDroplet(dropletId uint) (int, error) {
	path := fmt.Sprintf("droplets/%v/destroy", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("destroy malformed data %v", body)
	}

	return int(eventId), nil
}

func (d *DigitalOcean) ShowDroplet(dropletId uint) (*Droplet, error) {
	path := fmt.Sprintf("droplets/%v", dropletId)
	resp, err := digitalocean.NewRequest(*d.Client, path, url.Values{})
	if err != nil {
		return nil, err
	}

	droplet, ok := resp["droplet"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("show droplet malformed data received %v", resp)
	}

	var result Droplet
	if err := mapstructure.Decode(droplet, &result); err != nil {
		return nil, err
	}

	return &result, err
}

func (d *DigitalOcean) RenameDroplet(dropletId uint, newName string) (int, error) {
	params := url.Values{}
	params.Set("name", newName)

	path := fmt.Sprintf("droplets/%v/rename", dropletId)
	body, err := digitalocean.NewRequest(*d.Client, path, params)
	if err != nil {
		return 0, err
	}

	eventId, ok := body["event_id"].(float64)
	if !ok {
		return 0, fmt.Errorf("rename malformed data %v", body)
	}

	return int(eventId), nil
}
