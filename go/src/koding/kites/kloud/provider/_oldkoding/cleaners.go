package oldkoding

import (
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/multierrors"
	"koding/kites/kloud/protocol"
	"sync"
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
		// run for the first time
		if err := p.CleanLocks(CleanUpTimeout); err != nil {
			p.Log.Warning("Cleaning locks: %s", err)
		}

		if err := p.CleanDeletedVMs(); err != nil {
			p.Log.Warning("Cleaning deleted vms: %s", err)
		}

		if err := p.CleanStates(CleanUpTimeout); err != nil {
			p.Log.Warning("Cleaning states vms: %s", err)
		}

		if err := p.CleanNotInitializedVMs(); err != nil {
			p.Log.Warning("Cleaning states vms: %s", err)
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

	deleteMachine := func(machine MachineDocument) error {
		m := &protocol.Machine{
			Id:          machine.Id.Hex(),
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
			return p.Delete(m.Id)
		}

		p.Log.Info("[%s] cleaner: terminating user deleted machine. User %s",
			m.Id, m.Username)

		p.Destroy(m)

		return p.Delete(m.Id)
	}

	for _, machine := range machines {
		go func(machine MachineDocument) {
			if err := deleteMachine(machine); err != nil {
				p.Log.Error("[%s] couldn't terminate user deleted machine: %s",
					machine.Id.Hex(), err.Error())
			}

		}(machine)
	}

	return nil
}

// CleanNotInitializedVMs purges AWS machines that were created but wasn't used
// to finish the final build.
func (p *Provider) CleanNotInitializedVMs() error {
	machines := make([]MachineDocument, 0)

	query := func(c *mgo.Collection) error {
		// we remove machines which are set to NotInitialized and the state is
		// older than one hour. This means a build was started, we created a VM
		// but there was a problem and the build failed, but because the user
		// didn't continue the build the previously VM was never destroyed.
		unusedMachines := bson.M{
			"assignee.inProgress": false,
			"status.state":        machinestate.NotInitialized.String(),
			"status.modifiedAt":   bson.M{"$lt": time.Now().UTC().Add(-time.Hour)},
		}

		machine := MachineDocument{}
		iter := c.Find(unusedMachines).Batch(50).Iter()
		for iter.Next(&machine) {
			machines = append(machines, machine)
		}

		return iter.Close()
	}

	if err := p.Session.Run("jMachines", query); err != nil {
		return err
	}

	deleteMachine := func(machine MachineDocument) error {
		// if the machine has an empty instanceId just return
		if i, ok := machine.Meta["instanceId"]; ok {
			if instanceId, ok := i.(string); ok {
				if instanceId == "" {
					return nil
				}
			}
		} else {
			// also return if it doesn't exist
			return nil
		}

		m := &protocol.Machine{
			Id:          machine.Id.Hex(),
			Username:    machine.Credential, // contains the username for koding provider
			Provider:    machine.Provider,
			Builder:     machine.Meta,
			State:       machine.State(),
			IpAddress:   machine.IpAddress,
			QueryString: machine.QueryString,
			Eventer:     &eventer.Events{},
		}
		m.Domain.Name = machine.Domain

		p.Log.Info("[%s] cleaner: terminating NotInitialized user machine: %s",
			m.Id, m.Username)

		err := p.Destroy(m)

		p.Update(m.Id, &kloud.StorageData{
			// building state is normal, because we can clean up InstanceId
			// with this mode
			Type: "building",
			Data: map[string]interface{}{
				"instanceId":  "",
				"queryString": "",
			},
		})

		p.Log.Info("[%s] cleaner: cleaning up NotInitialized user machine finished: %s",
			m.Id, m.Username)

		return err
	}

	for _, machine := range machines {
		go func(machine MachineDocument) {
			if err := deleteMachine(machine); err != nil {
				p.Log.Error("[%s] couldn't terminate user deleted machine: %s",
					machine.Id.Hex(), err.Error())
			}
		}(machine)
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

// CleanStates resets documents that has machine states in progress mode
// (building, stopping, etc..) which weren't updated since 10 minutes. This
// could be caused because of Kloud restarts or panics.
func (p *Provider) CleanStates(timeout time.Duration) error {
	cleanstateFunc := func(badstate, goodstate string) error {
		return p.Session.Run("jMachines", func(c *mgo.Collection) error {
			// machines that can't be updated because they seems to be in progress
			badstateMachines := bson.M{
				"assignee.inProgress": false, // never update during a onging process :)
				"status.state":        badstate,
				"status.modifiedAt":   bson.M{"$lt": time.Now().UTC().Add(-timeout)},
			}

			cleanMachines := bson.M{
				"status.state":      goodstate,
				"status.modifiedAt": time.Now().UTC(),
			}

			// reset all machines
			info, err := c.UpdateAll(badstateMachines, bson.M{"$set": cleanMachines})
			if err != nil {
				return err
			}

			// only show if there is something, that will prevent spamming the
			// output with the same content over and over
			if info.Updated != 0 {
				p.Log.Info("[state cleaner] fixed %d documents from '%s' to '%s'",
					info.Updated, badstate, goodstate)
			}

			return nil
		})
	}

	progressModes := []struct {
		bad  string
		good string
	}{
		// our "build" method can continue with the leftover data that was
		// updated to MongoDB during the "build" process. So setting the state
		// to NotInitialized will make it to continue from where it was left.
		{machinestate.Building.String(), machinestate.NotInitialized.String()},
		{machinestate.Terminating.String(), machinestate.Terminated.String()},
		// once stopped, always stopped.
		{machinestate.Stopping.String(), machinestate.Stopped.String()},
		// the final state is  "stopped" because we don't know the if the
		// domains are updated or if the machien was really started. If the
		// machine is alrady started, the "start" method won't start it again,
		// so setting it to "stopped" will at least make it updating the
		// domains.
		{machinestate.Starting.String(), machinestate.Stopped.String()},
	}

	errs := multierrors.New()

	var wg sync.WaitGroup
	for _, state := range progressModes {
		wg.Add(1)
		go func(bad, good string) {
			defer wg.Done()
			err := cleanstateFunc(bad, good)
			errs.Add(err)
		}(state.bad, state.good)
	}

	wg.Wait()

	// if there is no errors just return a nil
	if errs.Len() == 0 {
		return nil
	}

	return errs
}
