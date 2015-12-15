package queue

import (
	"errors"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"koding/db/mongodb/modelhelper"
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
	q.Log.Debug("queue started with interval %s", interval)
	for _ = range time.Tick(interval) {
		// do not block the next tick
		go q.CheckKoding()
		go q.CheckAWS()
	}
}

func (q *Queue) CheckKoding() {
	machine := koding.NewMachine()
	err := q.FetchProvider("koding", machine.Machine)
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne err: %v", err)
		}

		// move one with the next one
		return
	}

	// Don't forget to set any important non-db related Machine values.
	machine.Locker = q.KodingProvider

	if err := q.CheckKodingUsage(machine); err != nil {
		// only log if it's something else
		switch err {
		case kite.ErrNoKitesAvailable,
			kontrol.ErrQueryFieldsEmpty,
			klient.ErrDialingFailed:
		default:
			q.Log.Debug("[%s] check usage of klient kite [%s] err: %v",
				machine.ObjectId.Hex(), machine.IpAddress, err)
		}
	}
}

// CheckUsage checks a single machine usages patterns and applies certain
// restrictions (if any available). For example it could stop a machine after a
// certain inactivity time.
func (q *Queue) CheckKodingUsage(m *koding.Machine) error {
	q.Log.Debug("Checking Koding machine\n%+v\n", m)
	if m == nil || m.Meta == nil {
		return errors.New("checking machine. document is nil")
	}

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	if meta.Region == "" {
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
		return q.StopIfKlientIsMissing(ctx, m)
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
		return q.StopIfKlientIsMissing(ctx, m)
	}

	// We successfully connected and communicated with Klient, clear the
	// missing value.
	if !m.Assignee.KlientMissingAt.IsZero() {
		err := modelhelper.UnsetKlientMissingAt(m.ObjectId)
		if err != nil {
			m.Log.Error("Defer Error: Call to klientIsNotMissing failed, %s", err.Error())
		}
	}

	// get the timeout from the plan in which the user belongs to
	plan := plans.Plans[m.Payment.Plan]
	planTimeout := plan.Timeout

	q.Log.Debug("machine [%s] (koding) is inactive for %s (plan limit: %s, plan: %s).",
		m.IpAddress, usg.InactiveDuration, planTimeout, m.Payment.Plan)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	q.Log.Info("machine [%s] has reached current plan limit of %s (plan: %s). Shutting down...",
		m.IpAddress, usg.InactiveDuration, m.Payment.Plan)

	// lock so it doesn't interfere with others.
	q.KodingProvider.Lock(m.ObjectId.Hex())
	defer q.KodingProvider.Unlock(m.ObjectId.Hex())

	// Hasta la vista, baby!
	q.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", m.ObjectId.Hex())

	if err := m.MarkAsStoppedWithReason("Machine is going to be stopped due inactivity"); err != nil {
		q.Log.Warning("[%s] ======> STOP state couldn't be saved (closing inactive machine: %s)<======", m.ObjectId.Hex(), err)
	}

	if err := m.StopMachine(ctx); err != nil {
		// returning is ok, because Kloud will mark it anyways as stopped if
		// Klient is not rechable anymore with the `info` method
		q.Log.Info("[%s] ======> STOP aborted (closing inactive machine: %s)<======", m.ObjectId.Hex(), err)
		return err
	}
	q.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", m.ObjectId.Hex())

	// mark it as stopped, so client side shouldn't ask for any eventer
	return m.MarkAsStoppedWithReason("Machine is stopped due inactivity")
}

// Fetch provider fetches the machine and populates the fields for the given
// provider.
func (q *Queue) FetchProvider(provider string, machine interface{}) error {
	query := func(c *mgo.Collection) error {
		// check only machines that:
		// 1. belongs to the given provider
		// 2. are running
		// 3. are not always on machines
		// 3. are not assigned to anyone yet (unlocked)
		// 4. are not picked up by others yet recently in last 30 seconds
		//
		// The $ne is used to catch documents whose field is not true including
		// that do not contain that particular field
		egligibleMachines := bson.M{
			"provider":            provider,
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
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Apply(update, machine)
		if err != nil {
			return err
		}

		return nil
	}

	return q.AwsProvider.DB.Run("jMachines", query)
}

// StopIfKlientIsMissing will stop the current Machine X minutes after
// the `assignee.klientMissingAt` value. If the value does not exist in
// the databse, it will write it and return.
//
// Therefor, this method is expected be called as often as needed,
// and will shutdown the Machine if klient has been missing for too long.
func (q *Queue) StopIfKlientIsMissing(ctx context.Context, m *koding.Machine) error {
	// If this is the first time Klient has been found missing,
	// set the missingat time and return
	if m.Assignee.KlientMissingAt.IsZero() {
		m.Log.Debug("Klient has been reported missing, recording this as the first time it went missing")

		return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				m.ObjectId,
				bson.M{"$set": bson.M{"assignee.klientMissingAt": time.Now().UTC()}},
			)
		})
	}

	// If the klient has been missing less than X minutes, don't stop
	if time.Since(m.Assignee.KlientMissingAt) < time.Minute*20 {
		return nil
	}

	// lock so it doesn't interfere with others.
	err := m.Lock()

	defer func(m *koding.Machine) {
		err := m.Unlock()
		if err != nil {
			m.Log.Error("Defer Error: Unlocking machine failed, %s", err.Error())
		}
	}(m)

	// Check for a Lock error
	if err != nil {
		return err
	}

	// Clear the klientMissingAt field, or we risk Stopping the user's
	// machine next time they run it, without waiting the proper X minute
	// timeout.
	defer func(m *koding.Machine) {
		if !m.Assignee.KlientMissingAt.IsZero() {
			err := modelhelper.UnsetKlientMissingAt(m.ObjectId)
			if err != nil {
				m.Log.Error("Defer Error: Call to klientIsNotMissing failed, %s", err.Error())
			}
		}
	}(m)

	// Hasta la vista, baby!
	m.Log.Info("======> STOP started (missing klient) <======, username:%s", m.Credential)
	if err := m.Stop(ctx); err != nil {
		m.Log.Info("======> STOP failed (missing klient: %s) <======", err)
		return err
	}
	m.Log.Info("======> STOP finished (missing klient) <======, username:%s", m.Credential)

	return nil
}
