package koding

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"

	"golang.org/x/net/context"
)

// Stop is a wrapper arround StopMachine, which also updates the mongoDB state.
func (m *Machine) Stop(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	if err := m.StopMachine(ctx); err != nil {
		// update the state to intial state if something goes wrong, we are going
		// to change latestate to a more safe state if we passed a certain step
		// below
		m.UpdateState("Machine is marked as "+m.State().String(), m.State())
		return err
	}

	return m.markAsStopped()
}

// StopMachine stops the given machine.
func (m *Machine) StopMachine(ctx context.Context) (err error) {
	err = m.Session.AWSClient.Stop(ctx)
	if err != nil {
		return err
	}

	m.push("Initializing domain instance", 65, machinestate.Stopping)
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		return err
	}

	m.push("Changing domain to sleeping mode", 85, machinestate.Stopping)
	if err := m.Session.DNSClient.Delete(m.Domain); err != nil {
		m.Log.Warning("couldn't delete domain %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unseting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Delete(domain.Name); err != nil {
			m.Log.Warning("couldn't delete domain %s", err)
		}
	}

	// try to release EIP if the user's plan is a free one
	if plan, ok := plans.Plans[m.Payment.Plan]; ok && plan == plans.Free {
		m.releaseEIP()
	}

	return nil
}
