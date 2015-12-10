package koding

import (
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/multierrors"
	"sync"
	"time"

	"golang.org/x/net/context"

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
	var machines []*Machine

	query := func(c *mgo.Collection) error {
		deletedMachines := bson.M{
			"userDeleted": true,
		}

		iter := c.Find(deletedMachines).Batch(50).Iter()
		for machine := NewMachine(); iter.Next(machine); machine = NewMachine() {
			if machine.Machine == nil {
				// TODO(rjeczalik): m.DeleteDocument() here
				p.Log.Warning("invalid jMachine encountered while cleaning: %+v", machine)
				continue
			}
			machines = append(machines, machine)
		}

		return iter.Close()
	}

	if err := p.DB.Run("jMachines", query); err != nil {
		return err
	}

	deleteMachine := func(m *Machine) error {
		ctx := context.Background()
		if err := p.AttachSession(ctx, m); err != nil {
			return err
		}

		meta, err := m.GetMeta()
		if err != nil {
			return err
		}

		if meta.InstanceId == "" {
			// if there is no instance Id just remove the document
			return m.DeleteDocument()
		}

		m.Log.Info("cleaner: terminating user deleted machine. User %s", m.Username)
		return m.Destroy(context.Background())
	}

	for _, machine := range machines {
		go func(m *Machine) {
			if err := deleteMachine(m); err != nil {
				p.Log.Error("[%s] couldn't terminate user deleted machine: %s",
					m.ObjectId.Hex(), err)
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

	return p.DB.Run("jMachines", query)
}

// CleanStates resets documents that has machine states in progress mode
// (building, stopping, etc..) which weren't updated since 10 minutes. This
// could be caused because of Kloud restarts or panics.
func (p *Provider) CleanStates(timeout time.Duration) error {
	cleanstateFunc := func(badstate, goodstate string) error {
		return p.DB.Run("jMachines", func(c *mgo.Collection) error {
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
