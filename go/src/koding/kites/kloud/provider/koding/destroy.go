package koding

import (
	"errors"
	"koding/kites/kloud/machinestate"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
)

// Destroy implements the Destroyer interface. It uses destroyMachine(ctx)
// function but updates/deletes the MongoDB document once finished.
func (m *Machine) Destroy(ctx context.Context) error {
	if m.State() == machinestate.NotInitialized {
		return errors.New("can't destroy notinitialized machine.")
	}

	if err := m.UpdateState("Machine is termating", machinestate.Terminating); err != nil {
		return err
	}

	if err := m.Session.AWSClient.Destroy(ctx, 10, 50); err != nil {
		return err
	}

	m.push("Deleting base domain", 85, machinestate.Terminating)
	if err := m.Session.DNSClient.Delete(m.Domain); err != nil {
		// if it's already deleted, for example because of a STOP, than we just
		// log it here instead of returning the error
		m.Log.Error("deleting domain during destroying err: %s", err.Error())
	}

	domains, err := m.Session.DNSStorage.GetByMachine(m.Id.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unsetting err: %s", err.Error())
	}

	m.push("Deleting custom domain", 90, machinestate.Terminating)
	for _, domain := range domains {
		if err := m.Session.DNSClient.Delete(domain.Name); err != nil {
			m.Log.Error("couldn't delete domain: %s", err.Error())
		}

		err := m.Session.DNSStorage.UpdateMachine(domain.Name, "")
		if err != nil {
			m.Log.Error("couldn't unset machine domain: %s", err.Error())
		}
	}

	// try to release/delete a public elastic IP, if there is an error we don't
	// care (the instance might not have an elastic IP, aka a free user.
	if resp, err := m.Session.AWSClient.Client.Addresses(
		[]string{m.IpAddress},
		nil,
		ec2.NewFilter(),
	); err == nil {
		if len(resp.Addresses) == 0 {
			return nil // nothing to do
		}

		address := resp.Addresses[0]
		m.Log.Debug("Got an elastic IP %+v. Going to relaease it", address)

		m.Session.AWSClient.Client.ReleaseAddress(address.AllocationId)
	}

	// clean up these details, the instance doesn't exist anymore
	m.Meta.InstanceId = ""
	m.Meta.InstanceName = ""
	m.IpAddress = ""
	m.QueryString = ""

	return m.DeleteDocument()
}
