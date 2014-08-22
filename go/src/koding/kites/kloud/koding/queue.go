package koding

import (
	"errors"
	"fmt"
	"koding/kites/klient/usage"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
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
			fmt.Printf("machineid %+v\n", machine.Id)

			if out, err := p.sendPing(machine.QueryString); err != nil {
				p.Log.Error("[%s] couldn't send ping to klient: %s", machine.Id.Hex(), err)
			} else {
				p.Log.Info("[%s] sent 'ping', received '%s'", machine.Id.Hex(), out)
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

func (p *Provider) sendPing(queryString string) (string, error) {
	query, _ := protocol.KiteFromString(queryString)

	kites, err := p.Kite.GetKites(query.Query())
	if err != nil {
		return "", err
	}

	remoteKlient := kites[0]
	if err := remoteKlient.Dial(); err != nil {
		return "", err
	}

	resp, err := remoteKlient.Tell("kite.ping")
	if err != nil {
		return "", err
	}

	return resp.String()
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
