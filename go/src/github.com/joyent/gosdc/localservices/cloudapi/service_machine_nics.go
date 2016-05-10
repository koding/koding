package cloudapi

import (
	"fmt"
	"time"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosdc/localservices"
)

func (c *CloudAPI) ListNICs(machineID string) ([]cloudapi.NIC, error) {
	machine, err := c.getMachineWrapper(machineID)
	if err != nil {
		return nil, err
	}

	out := []cloudapi.NIC{}
	for _, nic := range machine.NICs {
		out = append(out, *nic)
	}

	return out, nil
}

func (c *CloudAPI) GetNIC(machineID, MAC string) (*cloudapi.NIC, error) {
	machine, err := c.getMachineWrapper(machineID)
	if err != nil {
		return nil, err
	}

	nic, present := machine.NICs[MAC]
	if !present {
		return nil, fmt.Errorf("NIC with MAC %s not found", MAC)
	}

	return nic, nil
}

func (c *CloudAPI) AddNIC(machineID, networkID string) (*cloudapi.NIC, error) {
	machine, err := c.getMachineWrapper(machineID)
	if err != nil {
		return nil, err
	}

	// make sure that we're getting a real network
	_, err = c.GetNetwork(networkID)
	if err != nil {
		return nil, err
	}

	found := false
	for _, network := range machine.Networks {
		if network == networkID {
			found = true
		}
	}
	if found {
		return nil, fmt.Errorf("Machine %s is already in network %s", machineID, networkID)
	}

	mac, err := localservices.NewMAC()
	if err != nil {
		return nil, err
	}

	machine.NICs[mac] = &cloudapi.NIC{
		IP:      "10.88.88.100",
		MAC:     mac,
		Primary: false,
		Netmask: "255.255.255.0",
		Gateway: "10.88.88.2",
		State:   cloudapi.NICStateRunning,
		Network: networkID,
	}
	machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
	machine.Networks = append(machine.Networks, networkID)
	machine.NetworkNICs[mac] = networkID

	return machine.NICs[mac], nil
}

func (c *CloudAPI) RemoveNIC(machineID, MAC string) error {
	machine, err := c.getMachineWrapper(machineID)
	if err != nil {
		return err
	}

	_, present := machine.NICs[MAC]
	if !present {
		return fmt.Errorf("NIC with MAC %s not found", MAC)
	}

	machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
	destNetwork := machine.NetworkNICs[MAC]

	for i, network := range machine.Networks {
		if network == destNetwork {
			machine.Networks = append(machine.Networks[:i], machine.Networks[i+1:]...)
		}
	}

	delete(machine.NICs, MAC)
	delete(machine.NetworkNICs, MAC)

	return nil
}
