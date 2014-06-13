package api

import "github.com/mitchellh/packer/builder/digitalocean"

type Images []digitalocean.Image

func (i Images) Filter(name string) Images {
	return i
}
