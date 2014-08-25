package koding

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	FreeUserTimeout = time.Minute * 15
	CleanUpTimeout  = time.Minute
)

// RunChecker runs the checker every given interval time. It fetches a single
// document.
func (p *Provider) RunChecker(interval time.Duration) {
	for _ = range time.Tick(interval) {
		machine, err := p.FetchOne(interval)
		if err != nil {
			// do not show an error if the query didn't find anything, that
			// means there is no such a document, which we don't care
			if err != mgo.ErrNotFound {
				p.Log.Warning("FetchOne err: %v", err)
			}

			p.Log.Debug("checker no machines available to check: %s", err.Error())

			// move one with the next one
			continue
		}

		if err := p.CheckUsage(machine); err != nil {
			if err == kite.ErrNoKitesAvailable {
				p.Log.Warning("[%s] can't check machine (%s). klient kite is down, waiting...",
					machine.Id.Hex(), machine.IpAddress)
			} else {
				p.Log.Warning("check usage of kite err: %v", err)
			}
		}
	}
}

// RunCleaner runs the cleaner for the given timeout duration. It cleans
// up/resets machine documents.
func (p *Provider) RunCleaner(interval time.Duration) {
	for _ = range time.Tick(interval) {
		if err := p.CleanQueue(CleanUpTimeout); err != nil {
			p.Log.Warning("Cleaning queue: %s", err)
		}
	}
}

// CheckUsage checks a single machine usages patterns and applies certain
// restrictions (if any available). For example it could stop a machine after a
// certain inactivity time.
func (p *Provider) CheckUsage(machine *Machine) error {
	if machine == nil {
		return errors.New("machine is nil")
	}

	// release the lock from mongodb after we are done
	defer p.ResetAssignee(machine.Id.Hex())

	klient, err := p.Connect(machine.QueryString)
	if err != nil {
		return err
	}
	defer klient.Close()

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klient.Usage()
	if err != nil {
		p.Log.Error("[%s] couldn't get usage to klient: %s", machine.Id.Hex(), err)
		return err
	}

	p.Log.Info("[%s] machine with ip %s is inactive for %s",
		machine.Id.Hex(), machine.IpAddress, usg.InactiveDuration)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= FreeUserTimeout {
		return nil
	}

	credential := p.GetCredential(machine.Credential)

	// populare a protocol.Machine instance that is needed for the Stop()
	// method
	m := &protocol.Machine{
		MachineId:   machine.Id.Hex(),
		Provider:    machine.Provider,
		Builder:     machine.Meta,
		Credential:  credential.Meta,
		State:       machine.State(),
		CurrentData: machine,
	}

	m.Builder["username"] = klient.username

	// add a fake eventer, means we are not reporting anyone and prevent also
	// panicing when someone try to call the eventer
	m.Eventer = &eventer.Events{}

	// mark our state as stopping so otherws know what we are doing
	p.UpdateState(machine.Id.Hex(), machinestate.Stopping)

	// Hasta la vista, baby!
	err = p.Stop(m)
	if err != nil {
		return err
	}

	// update the state too
	return p.UpdateState(machine.Id.Hex(), machinestate.Stopped)
}

// FetchOne() fetches a single machine document from mongodb. This document is
// locked and cannot be retrieved from others anymore. After finishin work with
// this document ResetAssignee needs to be called that it's unlocked again and
// can be fetcy by others.
func (p *Provider) FetchOne(interval time.Duration) (*Machine, error) {
	machine := &Machine{}
	query := func(c *mgo.Collection) error {
		// check only machines that are running and belongs to koding provider
		// which are not assigned to anyone yet. We also check the date to not
		// pick up fresh documents. That means documents that are proccessed
		// and put into the DB will not selected until the interval has been
		// passed. The interval is the same as checkers interval.
		egligibleMachines := bson.M{
			"provider":            "koding",
			"status.state":        "Running",
			"assignee.inProgress": false,
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(-interval)},
		}

		// once we found something, lock it by modifing the assignee.name. Also
		// create a new timestamp (assignee.assignedAt) which is needed for
		// several cases like (explained above and below)
		change := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.inProgress": true,
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
			ReturnNew: true,
		}

		// We sort according to the latest assignment date, which let's us pick
		// always the oldest one instead of random/first. Returning an error
		// means there is no document that matches our criterias.
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Apply(change, &machine)
		if err != nil {
			return err
		}

		return nil
	}

	if err := p.Session.Run("jMachines", query); err != nil {
		return nil, err
	}

	return machine, nil
}

// CleanQueue resets documents that where locked by workers who died and left
// the documents untouched/unlocked. These documents are *ghost* documents,
// because they have an assignee that is not nil no worker will pick it up. The
// given timeout specifies
func (p *Provider) CleanQueue(timeout time.Duration) error {
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

		p.Log.Info("[checker] cleaned up %d documents", info.Updated)
		return nil
	}

	return p.Session.Run("jMachines", query)
}
