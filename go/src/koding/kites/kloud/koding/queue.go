package koding

import (
	"errors"
	"time"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	FreeUserTimeout = time.Minute * 5
)

// RunChecker runs the checker everny given interval time. It fetches a single
// document.
func (p *Provider) RunChecker(interval time.Duration) {
	for _ = range time.Tick(interval) {
		machine, err := p.FetchOne()
		if err != nil {
			// do not show an error if the query didn't find anything, that
			// means there is no such a document, which we don't care
			if err != mgo.ErrNotFound {
				p.Log.Error("FetchOne err: %v", err)
			}

			p.Log.Info("checker no machines available to check: %s", err.Error())

			// move one with the next one
			continue
		}

		if err := p.CheckUsage(machine); err != nil {
			p.Log.Warning("check usage of kite err: %v", err)
		}
	}
}

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

	usg, err := klient.Usage()
	if err != nil {
		p.Log.Error("[%s] couldn't get usage to klient: %s", machine.Id.Hex(), err)
		return err
	}

	p.Log.Info("[%s] machine with ip %s is inactive since %s",
		machine.Id.Hex(), machine.IpAddress, usg.InactiveDuration)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= FreeUserTimeout {
		return nil
	}

	// populare a protocol.Machine instance that is needed for the Stop()
	// method
	credential := p.GetCredential(machine.Credential)

	m := &protocol.Machine{
		MachineId:  machine.Id.Hex(),
		Provider:   machine.Provider,
		Builder:    machine.Meta,
		Credential: credential.Meta,
		State:      machine.State(),
	}
	m.CurrentData.IpAddress = machine.IpAddress
	m.Builder["username"] = "kloud"

	// add a fake eventer, meanse we are not reporting anyone and prevent also
	// panicing the code when someone try to call the eventer
	m.Eventer = &eventer.Events{}

	// stop the machine
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
func (p *Provider) FetchOne() (*Machine, error) {
	machine := &Machine{}
	query := func(c *mgo.Collection) error {
		// check only machines that are running and belongs to koding provider
		// which are not assigned to anyone yet
		egligibleMachines := bson.M{
			"provider":            "koding",
			"status.state":        "Running",
			"assignee.name":       nil,
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(time.Second * 10)},
		}

		// once we found something, lock it by modifing the assignee.name.
		change := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.name":       p.Assignee(),
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
			ReturnNew: true,
		}

		_, err := c.Find(egligibleMachines).Apply(change, &machine)
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
