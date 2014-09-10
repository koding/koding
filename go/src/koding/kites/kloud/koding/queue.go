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
	// Be cautious if your try to lower this. A build might really last more
	// than 10 minutes.
	CleanUpTimeout = time.Minute * 10
)

// RunChecker runs the checker every given interval time. It fetches a single
// document.
func (p *Provider) RunChecker(interval time.Duration) {
	for _ = range time.Tick(interval) {
		// do not block the next tick
		go func() {
			machine, err := p.FetchOne(interval)
			if err != nil {
				// do not show an error if the query didn't find anything, that
				// means there is no such a document, which we don't care
				if err != mgo.ErrNotFound {
					p.Log.Warning("FetchOne err: %v", err)
				}

				p.Log.Debug("checker no machines available to check: %s", err.Error())

				// move one with the next one
				return
			}

			if err := p.CheckUsage(machine); err != nil {
				if err == kite.ErrNoKitesAvailable {
					p.Log.Warning("[%s] can't check machine (%s). klient kite is not running yet, waiting...",
						machine.Id.Hex(), machine.IpAddress)
				} else {
					p.Log.Warning("[%s] check usage of kite [%s] err: %v",
						machine.Id.Hex(), machine.IpAddress, err)
				}
			}
		}()
	}
}

// RunCleaner runs the cleaner for the given timeout duration. It cleans
// up/resets machine documents.
func (p *Provider) RunCleaner(interval time.Duration) {
	// run for the first
	if err := p.CleanQueue(CleanUpTimeout); err != nil {
		p.Log.Warning("Cleaning queue: %s", err)
	}

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
	defer p.Unlock(machine.Id.Hex())

	credential := p.GetCredential(machine.Credential)

	// populate a protocol.Machine instance that is needed for the Stop()
	// method
	opts := &protocol.Machine{
		MachineId:   machine.Id.Hex(),
		Provider:    machine.Provider,
		Builder:     machine.Meta,
		Credential:  credential.Meta,
		State:       machine.State(),
		CurrentData: machine,
	}

	// will be replaced once we connect to klient in checker.Timeout() we are
	// adding it so it doesn't panic when someone tries to retrieve it
	opts.Builder["username"] = "kloud-checker"

	// add a fake eventer, means we are not reporting anyone and prevent also
	// panicing when someone try to call the eventer
	opts.Eventer = &eventer.Events{}

	checker, err := p.PlanChecker(opts)
	if err != nil {
		return err
	}

	// for now just check for timeout. This will dial the remote klient to get
	// the usage data
	return checker.Timeout()
}

// FetchOne() fetches a single machine document from mongodb. This document is
// locked and cannot be retrieved from others anymore. After finishing work with
// this document locker.Unlock() needs to be called that it's unlocked again
// so it can be fetched by others.
func (p *Provider) FetchOne(interval time.Duration) (*Machine, error) {
	machine := &Machine{}
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to koding provider
		// 2. are running
		// 3. are not always on machines
		// 4. are not assigned to anyone yet (unlocked)
		// 5. are not picked up by others yet recently
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particual field
		egligibleMachines := bson.M{
			"provider":            "koding",
			"status.state":        machinestate.Running.String(),
			"meta.alwaysOn":       bson.M{"$ne": true},
			"assignee.inProgress": bson.M{"$ne": true},
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(-interval)},
		}

		// once we found something, lock it by modifying the assignee.name. Also
		// create a new timestamp (assignee.assignedAt) which is needed for
		// several cases (explained above and below)
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
		// means there is no document that matches our criteria.
		_, err := c.Find(egligibleMachines).
			Sort("assignee.assignedAt").
			Apply(change, &machine)
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
// given timeout specificies to look up documents from now on.
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

		// only show if there is something, that will prevent spamming the
		// output with the same content over and over
		if info.Updated != 0 {
			p.Log.Info("[checker] cleaned up %d documents", info.Updated)
		}

		return nil
	}

	return p.Session.Run("jMachines", query)
}
