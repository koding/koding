package queue

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"koding/db/mongodb"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Queue struct {
	DB  *mongodb.MongoDB
	Log logging.Logger
}

// RunChecker runs the checker for Koding and AWS providers every given
// interval time. It fetches a single document.
func (q *Queue) RunCheckers(interval time.Duration) {
	for _ = range time.Tick(interval) {
		// do not block the next tick
		go q.CheckKoding()
	}
}

func (q *Queue) CheckKoding() {
	machine, err := q.FetchOne()
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne err: %v", err)
		}

		// move one with the next one
		return
	}

	if err := q.CheckUsage(machine); err != nil {
		// only log if it's something else
		switch err {
		case kite.ErrNoKitesAvailable,
			kontrol.ErrQueryFieldsEmpty,
			klient.ErrDialingFailed:
		default:
			q.Log.Debug("[%s] check usage of klient kite [%s] err: %v",
				machine.Id.Hex(), machine.IpAddress, err)
		}
	}
}

// CheckUsage checks a single machine usages patterns and applies certain
// restrictions (if any available). For example it could stop a machine after a
// certain inactivity time.
func (q *Queue) CheckUsage(m *Machine) error {
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
		m.Log.Debug("Error connecting to klient, stopping if needed. Error: %s",
			err.Error())
		return m.stopIfKlientIsMissing(ctx)
	}

	// replace with the real and authenticated username
	m.Username = klientRef.Username

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klientRef.Usage()

	// close the underlying connection once we get the usage
	klientRef.Close()
	klientRef = nil
	if err != nil {
		m.Log.Debug("Error getting klient usage, stopping if needed. Error: %s",
			err.Error())
		return m.stopIfKlientIsMissing(ctx)
	}

	// We successfully connected and communicated with Klient, clear the
	// missing value.
	m.klientIsNotMissing()

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
	defer p.Unlock(m.Id.Hex())

	// Hasta la vista, baby!
	p.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", m.Id.Hex())
	if err := m.stop(ctx); err != nil {
		// returning is ok, because Kloud will mark it anyways as stopped if
		// Klient is not rechable anymore with the `info` method
		p.Log.Info("[%s] ======> STOP aborted (closing inactive machine: %s)<======", m.Id.Hex(), err)
		return err
	}
	p.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", m.Id.Hex())

	// mark it as stopped, so client side shouldn't ask for any eventer
	return m.markAsStoppedWithReason("Machine is stopped due inactivity")
}

// FetchKoding() fetches a single machine document from mongodb that meets the criterias:
//
// 1. belongs to koding provider
// 2. are running
// 3. are not always on machines
// 4. are not assigned to anyone yet (unlocked)
// 5. are not picked up by others yet recently
func (q *Queue) FetchKoding() (*Machine, error) {
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

	if err := q.DB.Run("jMachines", query); err != nil {
		return nil, err
	}

	// Don't forget to set any important non-db related Machine values.
	machine.locker = q

	return machine, nil
}

func (q *Queue) Lock(id string) error {
	machine := &Machine{}
	err := q.DB.Run("jMachines", func(c *mgo.Collection) error {
		// we use findAndModify() to get a unique lock from the DB. That means only
		// one instance should be responsible for this action. We will update the
		// assignee if none else is doing stuff with it.
		change := mgo.Change{
			Update: bson.M{
				"$set": bson.M{
					"assignee.inProgress": true,
					"assignee.assignedAt": time.Now().UTC(),
				},
			},
			ReturnNew: true,
		}

		// if Find() is successful the Update() above will be applied (which
		// set's us as assignee by marking the inProgress to true). If not, it
		// means someone else is working on this document and we should return
		// with an error. The whole process is atomic and a single transaction.
		_, err := c.Find(
			bson.M{
				"_id": bson.ObjectIdHex(id),
				"assignee.inProgress": bson.M{"$ne": true},
			},
		).Apply(change, &machine) // machine is used just used for prevent nil unmarshalling
		return err
	})

	// query didn't matched, means it's assigned to some other Kloud
	// instances and an ongoing event is in process.
	if err == mgo.ErrNotFound {
		return kloud.ErrLockAcquired
	}

	// some other error, this shouldn't be happed
	if err != nil {
		q.Log.Error("Storage get error: %s", err.Error())
		return kloud.NewError(kloud.ErrBadState)
	}

	return nil
}

func (q *Queue) Unlock(id string) {
	q.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			bson.ObjectIdHex(id),
			bson.M{"$set": bson.M{"assignee.inProgress": false}},
		)
	})
}
