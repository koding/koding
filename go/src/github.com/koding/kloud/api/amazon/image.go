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
