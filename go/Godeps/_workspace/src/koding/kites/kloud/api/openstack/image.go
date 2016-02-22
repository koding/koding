package openstack

import (
	"errors"
	"fmt"

	"github.com/rackspace/gophercloud"
)

type Images []gophercloud.Image

func (i Images) String() string {
	out := ""
	for d, image := range i {
		out += fmt.Sprintf("[%d] name: %+v id: %+v\n", d, image.Name, image.Id)
	}
	return out
}

func (i Images) HasName(name string) bool {
	for _, image := range i {
		if image.Name == name {
			return true
		}
	}
	return false
}

func (i Images) ImageByName(name string) (gophercloud.Image, error) {
	for _, image := range i {
		if image.Name == name {
			return image, nil
		}
	}
	return gophercloud.Image{}, errors.New("image not found")
}

// Image returns a single image based on the given image id, slug or id. It
// checks for each occurency and returns for the first match.
func (o *Openstack) Image(id string) (*gophercloud.Image, error) {
	return o.Client.ImageById(id)
}

// Images returns all available images for this account
func (o *Openstack) Images() (Images, error) {
	return o.Client.ListImages()
}
