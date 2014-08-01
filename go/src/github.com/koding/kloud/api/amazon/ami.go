package amazon

import (
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

// Gets a private ami image id, based on the name provided
func (a *Amazon) AmiByName(name string) (string, error) {
	// Get new filter
	f := ec2.NewFilter()

	// Only with the name we want
	f.Add("name", name)

	resp, err := a.Client.Images([]string{}, f)
	if err != nil {
		return "", err
	}

	if len(resp.Images) != 1 {
		return "", fmt.Errorf("the AMI named '%s' could not be found", name)
	}

	return resp.Images[0].Id, nil
}
