package amazon

import (
	"fmt"

	"github.com/mitchellh/goamz/ec2"
)

func (a *Amazon) AddTag(instanceId, key, value string) error {
	tags := []ec2.Tag{{key, value}}
	_, err := a.Client.CreateTags([]string{instanceId}, tags)
	if err != nil {
		return fmt.Errorf("Failed to tag a Name on the builder instance: %s", err)
	}

	return nil
}

func (a *Amazon) AddTags(instanceId string, tags []ec2.Tag) error {
	_, err := a.Client.CreateTags([]string{instanceId}, tags)
	if err != nil {
		return fmt.Errorf("Failed to tag a Name on the builder instance: %s", err)
	}

	return nil
}
