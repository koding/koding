package cloudapi

import (
	"fmt"
	"time"
)

// GetMachineMetadata returns the complete set of metadata associated with the
// specified machine.
func (c *CloudAPI) GetMachineMetadata(machineID string) (map[string]string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return nil, err
	}

	return machine.Metadata, nil
}

// UpdateMachineMetadata updates the metadata for a given machine.
// Any metadata keys passed in here are created if they do not exist, and
// overwritten if they do.
func (c *CloudAPI) UpdateMachineMetadata(machineID string, metadata map[string]string) (map[string]string, error) {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return nil, err
	}

	for k, v := range metadata {
		machine.Metadata[k] = v
	}
	machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")

	return metadata, nil
}

// DeleteMachineMetadata deletes a single metadata key from the specified machine
func (c *CloudAPI) DeleteMachineMetadata(machineID string, key string) error {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	_, ok := machine.Metadata[key]
	if !ok {
		return fmt.Errorf(`"%s" is not a metadata key`, key)
	}

	delete(machine.Metadata, key)
	return nil
}

// DeleteAllMachineMetadata deletes all metadata keys from the specified machine.
func (c *CloudAPI) DeleteAllMachineMetadata(machineID string) error {
	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	for k := range machine.Metadata {
		delete(machine.Metadata, k)
	}
	return nil
}
