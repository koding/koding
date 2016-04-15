package cloudapi

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/joyent/gosdc/cloudapi"
	"github.com/joyent/gosdc/localservices"
)

// ListMachines returns a list of machines in the double
func (c *CloudAPI) ListMachines(filters map[string]string) ([]*cloudapi.Machine, error) {
	if err := c.ProcessFunctionHook(c, filters); err != nil {
		return nil, err
	}

	availableMachines := c.machines

	if filters != nil {
		for k, f := range filters {
			// check if valid filter
			if contains(machinesFilters, k) {
				machines := []*machine{}
				// filter from availableMachines and add to machines
				for _, m := range availableMachines {
					if k == "name" && m.Name == f {
						machines = append(machines, m)
					} else if k == "type" && m.Type == f {
						machines = append(machines, m)
					} else if k == "state" && m.State == f {
						machines = append(machines, m)
					} else if k == "image" && m.Image == f {
						machines = append(machines, m)
					} else if k == "memory" {
						i, err := strconv.Atoi(f)
						if err == nil && m.Memory == i {
							machines = append(machines, m)
						}
					} else if strings.HasPrefix(k, "tags.") {
						for t, v := range m.Tags {
							if t == k[strings.Index(k, ".")+1:] && v == f {
								machines = append(machines, m)
							}
						}
					}
				}
				availableMachines = machines
			}
		}
	}

	out := make([]*cloudapi.Machine, len(availableMachines))
	for i, machine := range availableMachines {
		out[i] = &machine.Machine
	}

	return out, nil
}

// CountMachines returns a count of machines the double knows about
func (c *CloudAPI) CountMachines() (int, error) {
	if err := c.ProcessFunctionHook(c); err != nil {
		return 0, err
	}

	return len(c.machines), nil
}

func (c *CloudAPI) getMachineWrapper(machineID string) (*machine, error) {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return nil, err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			return machine, nil
		}
	}

	return nil, fmt.Errorf("Machine %s not found", machineID)
}

// GetMachine gets a single machine by ID from the double
func (c *CloudAPI) GetMachine(machineID string) (*cloudapi.Machine, error) {
	wrapper, err := c.getMachineWrapper(machineID)
	if err != nil {
		return nil, err
	}

	return &wrapper.Machine, nil
}

// CreateMachine creates a new machine in the double. It will be running immediately.
func (c *CloudAPI) CreateMachine(name, pkg, image string, networks []string, metadata, tags map[string]string) (*cloudapi.Machine, error) {
	if err := c.ProcessFunctionHook(c, name, pkg, image); err != nil {
		return nil, err
	}

	machineID, err := localservices.NewUUID()
	if err != nil {
		return nil, err
	}

	mPkg, err := c.GetPackage(pkg)
	if err != nil {
		return nil, err
	}

	mImg, err := c.GetImage(image)
	if err != nil {
		return nil, err
	}

	mNetworks := []string{}
	for _, network := range networks {
		mNetwork, err := c.GetNetwork(network)
		if err != nil {
			return nil, err
		}

		mNetworks = append(mNetworks, mNetwork.Id)
	}

	publicIP := generatePublicIPAddress()

	newMachine := cloudapi.Machine{
		Id:        machineID,
		Name:      name,
		Type:      mImg.Type,
		State:     "running",
		Memory:    mPkg.Memory,
		Disk:      mPkg.Disk,
		IPs:       []string{publicIP, generatePrivateIPAddress()},
		Created:   time.Now().Format("2013-11-26T19:47:13.448Z"),
		Package:   pkg,
		Image:     image,
		Metadata:  metadata,
		Tags:      tags,
		PrimaryIP: publicIP,
		Networks:  mNetworks,
	}

	nics := map[string]*cloudapi.NIC{}
	nicNetworks := map[string]string{}
	for i, network := range mNetworks {
		mac, err := localservices.NewMAC()
		if err != nil {
			return nil, err
		}

		nics[mac] = &cloudapi.NIC{
			IP:      fmt.Sprintf("10.88.88.%d", i),
			MAC:     mac,
			Primary: i == 0,
			Netmask: "255.255.255.0",
			Gateway: "10.88.88.2",
			State:   cloudapi.NICStateRunning,
			Network: network,
		}
		nicNetworks[mac] = network
	}

	c.machines = append(c.machines, &machine{newMachine, nics, nicNetworks})

	return &newMachine, nil
}

// StopMachine changes a machine's status to "stopped"
func (c *CloudAPI) StopMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			machine.State = "stopped"
			machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
			return nil
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}

// StartMachine changes a machine's state to "running"
func (c *CloudAPI) StartMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			machine.State = "running"
			machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
			return nil
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}

// RebootMachine changes a machine's state to "running" and updates Updated
func (c *CloudAPI) RebootMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			machine.State = "running"
			machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
			return nil
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}

// ResizeMachine changes a machine's package to a new size. Unlike the real API,
// this method lets you downsize machines.
func (c *CloudAPI) ResizeMachine(machineID, packageName string) error {
	if err := c.ProcessFunctionHook(c, machineID, packageName); err != nil {
		return err
	}

	mPkg, err := c.GetPackage(packageName)
	if err != nil {
		return err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			machine.Package = packageName
			machine.Memory = mPkg.Memory
			machine.Disk = mPkg.Disk
			machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
			return nil
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}

// RenameMachine changes a machine's name
func (c *CloudAPI) RenameMachine(machineID, newName string) error {
	if err := c.ProcessFunctionHook(c, machineID, newName); err != nil {
		return err
	}

	for _, machine := range c.machines {
		if machine.Id == machineID {
			machine.Name = newName
			machine.Updated = time.Now().Format("2013-11-26T19:47:13.448Z")
			return nil
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}

// ListMachineFirewallRules returns a list of firewall rules that apply to the
// given machine
func (c *CloudAPI) ListMachineFirewallRules(machineID string) ([]*cloudapi.FirewallRule, error) {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return nil, err
	}

	fwRules := []*cloudapi.FirewallRule{}
	for _, r := range c.firewallRules {
		vm := "vm " + machineID
		if strings.Contains(r.Rule, vm) {
			fwRules = append(fwRules, r)
		}
	}

	return fwRules, nil
}

// EnableFirewallMachine enables the firewall for the given machine
func (c *CloudAPI) EnableFirewallMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	machine.FirewallEnabled = true

	return nil
}

// DisableFirewallMachine disables the firewall for the given machine
func (c *CloudAPI) DisableFirewallMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	machine, err := c.GetMachine(machineID)
	if err != nil {
		return err
	}

	machine.FirewallEnabled = false

	return nil
}

// DeleteMachine deletes the given machine from the double
func (c *CloudAPI) DeleteMachine(machineID string) error {
	if err := c.ProcessFunctionHook(c, machineID); err != nil {
		return err
	}

	for i, machine := range c.machines {
		if machine.Id == machineID {
			if machine.State == "stopped" {
				c.machines = append(c.machines[:i], c.machines[i+1:]...)
				return nil
			}

			return fmt.Errorf("Cannot Delete machine %s, machine is not stopped.", machineID)
		}
	}

	return fmt.Errorf("Machine %s not found", machineID)
}
