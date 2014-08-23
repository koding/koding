package amazon

import (
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) Image(id string) (*ec2.Image, error) {
	resp, err := a.Client.Images([]string{id}, ec2.NewFilter())
	if err != nil {
		return nil, err
	}

	if len(resp.Images) != 1 {
		return nil, fmt.Errorf("the source AMI '%s' could not be found", id)
	}

	image := resp.Images[0]

	return &image, nil
}

// ImageByName returns an ec2.Image associated to the provided name
func (a *Amazon) ImageByName(name string) (*ec2.Image, error) {
	// Get new filter
	f := ec2.NewFilter()

	// Only with the name we want
	f.Add("name", name)

	resp, err := a.Client.Images([]string{}, f)
	if err != nil {
		return nil, err
	}

	if len(resp.Images) != 1 {
		return nil, fmt.Errorf("The AMI image named '%s' could not be found", name)
	}

	return &resp.Images[0], nil
}

// ImageByName returns an ec2.Image associated to the provided name
func (a *Amazon) ImageByTag(tagValue string) (*ec2.Image, error) {
	// Get new filter
	f := ec2.NewFilter()

	// Only with the name we want
	f.Add("tag:Name", tagValue)

	resp, err := a.Client.Images([]string{}, f)
	if err != nil {
		return nil, err
	}

	if len(resp.Images) != 1 {
		return nil, fmt.Errorf("The AMI image with tag '%s' could not be found", tagValue)
	}

	return &resp.Images[0], nil
}
