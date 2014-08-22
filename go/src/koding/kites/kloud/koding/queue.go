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

func (p *Provider) RunChecker() error {
	return nil
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
