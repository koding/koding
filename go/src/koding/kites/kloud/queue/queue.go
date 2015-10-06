package queue

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/koding"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Queue struct {
	KodingProvider *koding.Provider
	AwsProvider    *awsprovider.Provider
	Log            logging.Logger
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
	machine, err := q.FetchKoding()
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne err: %v", err)
		}

		// move one with the next one
		return
	}

	if err := q.CheckKodingUsage(machine); err != nil {
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
func (q *Queue) CheckKodingUsage(m *koding.Machine) error {
	if m == nil {
		return errors.New("checking machine. document is nil")
	}

	if m.Meta.Region == "" {
		return errors.New("region is not set in.")
	}

	ctx := context.Background()

	if err := q.KodingProvider.AttachSession(ctx, m); err != nil {
		return err
	}

	// Check klient state before rushing to AWS.
	klientRef, err := klient.Connect(m.Session.Kite, m.QueryString)
	if err != nil {
		m.Log.Debug("Error connecting to klient, stopping if needed. Error: %s",
			err.Error())
		return m.StopIfKlientIsMissing(ctx)
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
		return m.StopIfKlientIsMissing(ctx)
	}

	// We successfully connected and communicated with Klient, clear the
	// missing value.
	m.KlientIsNotMissing()

	// get the timeout from the plan in which the user belongs to
	plan := plans.Plans[m.Payment.Plan]
	planTimeout := plan.Timeout

	q.Log.Debug("machine [%s] is inactive for %s (plan limit: %s, plan: %s).",
		m.IpAddress, usg.InactiveDuration, planTimeout, m.Payment.Plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	q.Log.Info("machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		m.IpAddress, usg.InactiveDuration, m.Payment.Plan)

	// lock so it doesn't interfere with others.
	q.KodingProvider.Lock(m.Id.Hex())
	defer q.KodingProvider.Unlock(m.Id.Hex())

	// Hasta la vista, baby!
	q.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", m.Id.Hex())
	if err := m.StopMachine(ctx); err != nil {
		// returning is ok, because Kloud will mark it anyways as stopped if
		// Klient is not rechable anymore with the `info` method
		q.Log.Info("[%s] ======> STOP aborted (closing inactive machine: %s)<======", m.Id.Hex(), err)
		return err
	}
	q.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", m.Id.Hex())

	// mark it as stopped, so client side shouldn't ask for any eventer
	return m.MarkAsStoppedWithReason("Machine is stopped due inactivity")
}

// FetchKoding() fetches a single machine document from mongodb that meets the criterias:
//
// 1. belongs to koding provider
// 2. are running
// 3. are not always on machines
// 4. are not assigned to anyone yet (unlocked)
// 5. are not picked up by others yet recently
func (q *Queue) FetchKoding() (*koding.Machine, error) {
	machine := &koding.Machine{}
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

	if err := q.KodingProvider.DB.Run("jMachines", query); err != nil {
		return nil, err
	}

	// Don't forget to set any important non-db related Machine values.
	machine.Locker = q.KodingProvider

	return machine, nil
}
