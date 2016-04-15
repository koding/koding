package cloudapi

import "fmt"

// ListMachineTags returns the complete set of tags associated with the specified machine.
func (c *CloudAPI) ListMachineTags(machineID string) (map[string]string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return nil, err
	}

	return machine.Tags, nil
}

// AddMachineTags adds additional tags to the specified machine.
// This API lets you append new tags, not overwrite existing tags.
func (c *CloudAPI) AddMachineTags(machineID string, tags map[string]string) (map[string]string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return nil, err
	}

	for tag, value := range tags {
		if _, present := machine.Tags[tag]; !present {
			machine.Tags[tag] = value
		}
	}

	return machine.Tags, nil
}

// ReplaceMachineTags replaces existing tags for the specified machine.
// This API lets you overwrite existing tags, not append to existing tags.
func (c *CloudAPI) ReplaceMachineTags(machineID string, tags map[string]string) (map[string]string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return nil, err
	}

	for tag, value := range tags {
		if _, present := machine.Tags[tag]; present {
			machine.Tags[tag] = value
		}
	}

	return machine.Tags, nil
}

// DeleteMachineTags deletes all tags from the specified machine.
func (c *CloudAPI) DeleteMachineTags(machineID string) error {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	for tag := range machine.Tags {
		delete(machine.Tags, tag)
	}

	return nil
}

func (c *CloudAPI) DeleteMachineTag(machineID, tagKey string) error {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	_, present := machine.Tags[tagKey]
	if !present {
		return fmt.Errorf(`tag "%s" not found`, tagKey)
	}

	delete(machine.Tags, tagKey)
	return nil
}

// GetMachineTag returns the value for a single tag on the specified machine.
func (c *CloudAPI) GetMachineTag(machineID, tagKey string) (string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return "", err
	}

	val, ok := machine.Tags[tagKey]
	if !ok {
		return "", fmt.Errorf(`tag "%s" not found`, tagKey)
	}

	return val, nil
}
