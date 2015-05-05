package koding

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"golang.org/x/net/context"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

// RunChecker runs the checker every given interval time. It fetches a single
// document.
func (p *Provider) RunChecker(interval time.Duration) {
	for _ = range time.Tick(interval) {
		// do not block the next tick
		go func() {
			machine, err := p.FetchOne()
			if err != nil {
				// do not show an error if the query didn't find anything, that
				// means there is no such a document, which we don't care
				if err != mgo.ErrNotFound {
					p.Log.Warning("FetchOne err: %v", err)
				}

				// move one with the next one
				return
			}

			if err := p.CheckUsage(machine); err != nil {
				// only log if it's something else
				if err != kite.ErrNoKitesAvailable {
					p.Log.Error("[%s] check usage of klient kite [%s] err: %v",
						machine.Id.Hex(), machine.IpAddress, err)
				}
			}
		}()
	}
}

// CheckUsage checks a single machine usages patterns and applies certain
// restrictions (if any available). For example it could stop a machine after a
// certain inactivity time.
func (p *Provider) CheckUsage(m *Machine) error {
	if m == nil {
		return errors.New("checking machine. document is nil")
	}

	if m.Meta.Region == "" {
		return errors.New("region is not set in.")
	}

	ctx := context.Background()
	if err := p.attachSession(ctx, m); err != nil {
		return err
	}

	// Check klient state before rushing to AWS.
	klientRef, err := klient.Connect(m.Session.Kite, m.QueryString)
	if err != nil {
		return err
	}

	// replace with the real and authenticated username
	m.Username = klientRef.Username

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klientRef.Usage()

	// close the underlying connection once we get the usage
	klientRef.Close()
	klientRef = nil
	if err != nil {
		return err
	}

	// get the timeout from the plan in which the user belongs to
	plan := plans.Plans[m.Payment.Plan]
	planTimeout := plan.Timeout

	p.Log.Debug("machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		m.IpAddress, usg.InactiveDuration, planTimeout, m.Payment.Plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	p.Log.Info("machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		m.IpAddress, usg.InactiveDuration, m.Payment.Plan)

	// lock so it doesn't interfere with others.
	p.Lock(m.Id.Hex())
	defer func() {
		p.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", m.Id.Hex())
		p.Unlock(m.Id.Hex())
	}()

	// mark it as stopped, so client side shouldn't ask for any eventer
	if err := m.markAsStopped(); err != nil {
		return err
	}

	p.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", m.Id.Hex())
	// Hasta la vista, baby!
	return m.stop(ctx)
}

// FetchOne() fetches a single machine document from mongodb that meets the criterias:
//
// 1. belongs to koding provider
// 2. are running
// 3. are not always on machines
// 4. are not assigned to anyone yet (unlocked)
// 5. are not picked up by others yet recently
func (p *Provider) FetchOne() (*Machine, error) {
	machine := &Machine{}
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to koding provider
		// 2. are running
		// 3. are not always on machines
		// 4. are not assigned to anyone yet (unlocked)
		// 5. are not picked up by others yet recently in last 30 seconds
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particular field
		egligibleMachines := bson.M{
			"provider":            "koding",
			"status.state":        machinestate.Running.String(),
			"meta.alwaysOn":       bson.M{"$ne": true},
			"assignee.inProgress": bson.M{"$ne": true},
			"assignee.assignedAt": bson.M{"$lt": time.Now().UTC().Add(-time.Second * 30)},
		}

		// update so we don't pick up recent things
		update := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
		}

		// We sort according to the latest assignment date, which let's us pick
		// always the oldest one instead of random/first. Returning an error
		// means there is no document that matches our criteria.
		// err := c.Find(egligibleMachines).Sort("assignee.assignedAt").One(&machine)
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Apply(update, &machine)
		if err != nil {
			return err
		}

		return nil
	}

	if err := p.DB.Run("jMachines", query); err != nil {
		return nil, err
	}

	return machine, nil
}
