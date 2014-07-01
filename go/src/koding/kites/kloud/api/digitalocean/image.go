package api

import (
	"net/url"

	"github.com/mitchellh/mapstructure"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type Images []digitalocean.Image

func (i Images) Filter(name string) Images {
	return i
}

// Image returns a single image based on the given snaphot name, slug or id. It
// checks for each occurency and returns for the first match.
func (d *DigitalOcean) Image(slug_or_name_or_id string) (digitalocean.Image, error) {
	return d.Client.Image(slug_or_name_or_id)
}

// Image returns a slice of all images.
func (d *DigitalOcean) Images(myImages bool) (Images, error) {
	v := url.Values{}

	if myImages {
		v.Set("filter", "my_images")
	}

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
