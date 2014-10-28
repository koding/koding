package koding

import (
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/protocol"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	// Be cautious if your try to lower this. A build might really last more
	// than 10 minutes.
	CleanUpTimeout = time.Minute * 10
)

// RunCleaner runs the given cleaners for the given timeout duration. It cleans
// up/resets machine documents and VM leftovers.
func (p *Provider) RunCleaners(interval time.Duration) {
	cleaners := func() {
		// run for the first
		if err := p.CleanLocks(CleanUpTimeout); err != nil {
			p.Log.Warning("Cleaning locks: %s", err)
		}

		if err := p.CleanDeletedVMs(); err != nil {
			p.Log.Warning("Cleaning deleted vms: %s", err)
		}
	}

	cleaners()
	for _ = range time.Tick(interval) {
		go cleaners() // do not block
	}
}

// CleanDeletedVMS deletes VMs that have userDeleted set to true. This happens
// when the user deletes their account but kloud couldn't delete/terminate
// their VM's. This can happen for example if the user deletes their VM during
// an ongoing (build, start, stop...) process. There will be a lock due Build
// which will prevent to delete it.
func (p *Provider) CleanDeletedVMs() error {
	machines := make([]MachineDocument, 0)

	query := func(c *mgo.Collection) error {
		deletedMachines := bson.M{
			"userDeleted": true,
		}

		machine := MachineDocument{}
		iter := c.Find(deletedMachines).Batch(50).Iter()
		for iter.Next(&machine) {
			machines = append(machines, machine)
		}

		return iter.Close()
	}

	if err := p.Session.Run("jMachines", query); err != nil {
		return err
	}

	deleteMachine := func(id string) error {
		// we don't use p.Get() because it checks the user existence too,
		// however for deleted machines there are no users
		machine := &MachineDocument{}
		if err := p.Session.Run("jMachines", func(c *mgo.Collection) error {
			return c.FindId(bson.ObjectIdHex(id)).One(&machine)
		}); err != nil {
			return err
		}

		m := &protocol.Machine{
			Id:          id,
			Username:    machine.Credential, // contains the username for koding provider
			Provider:    machine.Provider,
			Builder:     machine.Meta,
			State:       machine.State(),
			IpAddress:   machine.IpAddress,
			QueryString: machine.QueryString,
			Eventer:     &eventer.Events{},
		}
		m.Domain.Name = machine.Domain

		// if there is no instance Id just remove the document
		if _, ok := m.Builder["instanceId"]; !ok {
			return p.Delete(id)
		}

		p.Log.Info("[%s] terminating user deleted machine. User %s",
			id, m.Username)

		if err := p.Destroy(m); err != nil {
			return err
		}

		return p.Delete(id)
	}

	for _, machine := range machines {
		if err := deleteMachine(machine.Id.Hex()); err != nil {
			p.Log.Error("[%s] couldn't terminate user deleted machine: %s",
				machine.Id.Hex(), err.Error())
		}
	}

	return nil
}

// CleanLocks resets documents that where locked by workers who died and left
// the documents untouched/unlocked. These documents are *ghost* documents,
// because they have an assignee that is not nil no worker will pick it up. The
// given timeout specificies to look up documents from now on.
func (p *Provider) CleanLocks(timeout time.Duration) error {
	query := func(c *mgo.Collection) error {
		// machines that can't be updated because they seems to be in progress
		ghostMachines := bson.M{
			"assignee.inProgress": true,
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(-timeout)},
		}

		cleanMachines := bson.M{
			"assignee.inProgress": false,
			"assignee.assignedAt": time.Now().UTC(),
		}

		// reset all machines
		info, err := c.UpdateAll(ghostMachines, bson.M{"$set": cleanMachines})
		if err != nil {
			return err
		}

		// only show if there is something, that will prevent spamming the
		// output with the same content over and over
		if info.Updated != 0 {
			p.Log.Info("[checker] cleaned up %d documents", info.Updated)
		}

		return nil
	}

	return p.Session.Run("jMachines", query)
}
