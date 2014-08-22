package koding

import (
	"errors"
	"fmt"
	"koding/kites/klient/usage"
	"time"

	"github.com/koding/kite"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	CheckInterval = time.Second * 2
)

func (p *Provider) RunChecker() {
	query := func(c *mgo.Collection) error {
		machine := Machine{}

		// check only machines that are running and belongs to koding provider
		runningMachines := bson.M{
			"provider":     "koding",
			"status.state": "Running",
		}

		iter := c.Find(runningMachines).Batch(50).Iter()
		for iter.Next(&machine) {
			// p.Log.Info("[%s] getting usage", machine.Id.Hex())

			klient, err := p.Klient(machine.QueryString)
			if err != nil {
				p.Log.Error("[%s] couldn't create klient instance: %s", machine.Id.Hex(), err)
				continue
			}

			if err := klient.Usage(); err != nil {
				p.Log.Error("[%s] couldn't get usage to klient: %s", machine.Id.Hex(), err)
			}
		}

		return iter.Close()
	}

	for _ = range time.Tick(CheckInterval) {
		if err := p.Session.Run("jMachines", query); err != nil {
			p.Log.Error("Checker err: %v", err)
		}
	}
}

func (p *Provider) Report(r *kite.Request) (interface{}, error) {
	var usg usage.Usage
	err := r.Args.One().Unmarshal(&usg)
	if err != nil {
		return nil, err
	}

	m := &Machine{}
	err = p.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"queryString": r.Client.Kite.String()}).One(&m)
	})
	if err != nil {
		p.Log.Warning("Couldn't find %v, however this kite is still reporting to us. Needs to be fixed: %s",
			r.Client.Kite, err.Error())
		return nil, errors.New("can't update report - 1")
	}

	machine, err := p.Get(m.Id.Hex(), r.Username)
	if err != nil {
		return nil, err
	}
	// release the lock from mongodb after we are done
	defer p.ResetAssignee(machine.MachineId)

	fmt.Printf("usage: %+v\n", usg)
	if usg.InactiveDuration >= time.Minute*30 {
		p.Log.Info("Stopping machine %s", machine.MachineId)

		err := p.Stop(machine)
		if err != nil {
			return nil, err
		}

		return "machine is stopped", nil
	}

	p.Log.Info("Machine '%s' is good to go", r.Client.Kite.ID)
	return true, nil
}
