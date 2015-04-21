package koding

import (
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"
)

var (
	// This is an AWS Server which serves a basic HTML page
	DefaultFallbackIP = "54.173.20.34"
)

func (m *Machine) Stop(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is stopping", machinestate.Stopping); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	err = m.Session.AWSClient.Stop(ctx)
	if err != nil {
		return err
	}

	latestState = machinestate.Stopped

	m.push("Initializing domain instance", 65, machinestate.Stopping)
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		return err
	}

	m.push("Changing domain to sleeping mode", 85, machinestate.Stopping)
	if err := m.Session.DNSClient.Upsert(m.Domain, DefaultFallbackIP); err != nil {
		m.Log.Warning("couldn't upsert domain %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := m.Session.DNSStorage.GetByMachine(m.Id.Hex())
	if err != nil {
		m.Log.Error("fetching domains for unseting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Upsert(domain.Name, DefaultFallbackIP); err != nil {
			m.Log.Warning("couldn't upsert domain %s", err)
		}
	}

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         "",
				"status.state":      machinestate.Stopped.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is stopped",
			}},
		)
	})
}
