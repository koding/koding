package queue

import (
	"context"
	"fmt"
	"time"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/utils/object"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"github.com/koding/logging"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	defaultInterval = 15 * time.Second
	planTimeout     = 50 * time.Minute
)

type Queue struct {
	Log      logging.Logger
	Interval time.Duration
	MongoDB  *mongodb.MongoDB
	Kite     *kite.Kite

	stackers map[string]*provider.Stacker
}

// RunChecker runs the checker for Koding and AWS providers every given
// interval time. It fetches a single document.
func (q *Queue) Run() {
	q.Log.Debug("queue started with interval %s", q.interval())

	t := time.NewTicker(q.interval())
	defer t.Stop()

	for range t.C {
		for _, s := range q.stackers {

			go func(s *provider.Stacker) {
				if err := q.Check(s); err != nil {
					q.Log.Debug("failed to check %q provider: %s", s.Provider.Name, err)
				}
			}(s)
		}
	}
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
		_, err := c.Find(egligibleMachines).Sort("assignee.assignedAt").Limit(1).Apply(update, machine)
		return err
	}

	return q.MongoDB.Run("jMachines", query)
}

func (q *Queue) Register(s *provider.Stacker) {
	if q.stackers == nil {
		q.stackers = make(map[string]*provider.Stacker)
	}

	if _, ok := q.stackers[s.Provider.Name]; ok {
		panic("queue: duplicate stacker: " + s.Provider.Name)
	}

	q.stackers[s.Provider.Name] = s
}

func (q *Queue) interval() time.Duration {
	if q.Interval != 0 {
		return q.Interval
	}

	return defaultInterval
}

func (q *Queue) Check(s *provider.Stacker) error {
	var m models.Machine

	err := q.FetchProvider(s.Provider.Name, &m)
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err == mgo.ErrNotFound {
			return nil
		}

		q.Log.Debug("no running machines for %q provider found", s.Provider.Name)

		return fmt.Errorf("check %q provider error: %s", s.Provider.Name, err)
	}

	req := &kite.Request{
		Method: "internal",
	}

	if u := m.Owner(); u != nil {
		req.Username = u.Username
	}

	ctx := request.NewContext(context.Background(), req)

	bm, err := s.BuildBaseMachine(ctx, &m)
	if err != nil {
		return err
	}

	machine, err := s.BuildMachine(ctx, bm)
	if err != nil {
		return err
	}

	switch err := q.CheckUsage(s.Provider.Name, machine, bm, ctx); err {
	case nil:
		return nil
	case kite.ErrNoKitesAvailable, kontrol.ErrQueryFieldsEmpty, klient.ErrDialingFailed:
		return nil
	default:
		return fmt.Errorf("[%s] check usage of AWS klient kite [%s] err: %s", m.ObjectId.Hex(), m.IpAddress, err)
	}
}

func (q *Queue) CheckUsage(providerName string, m provider.Machine, bm *provider.BaseMachine, ctx context.Context) error {
	q.Log.Debug("Checking %q machine\n%+v\n", providerName, bm.Machine)

	c, err := klient.Connect(q.Kite, bm.QueryString)
	if err != nil {
		q.Log.Debug("Error connecting to klient, stopping if needed. Error: %s", err)
		return err
	}

	// replace with the real and authenticated username
	if bm.User == nil {
		bm.User = &models.User{}
	}

	bm.User.Name = c.Username

	// get the usage directly from the klient, which is the most predictable source
	usg, err := c.Usage()
	c.Close() // close the underlying connection once we get the usage
	if err != nil {
		return fmt.Errorf("failure getting %q klient usage: %s", bm.QueryString, err)
	}

	q.Log.Debug("machine [%s] (aws) is inactive for %s (plan limit: %s)",
		bm.IpAddress, usg.InactiveDuration, planTimeout)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	q.Log.Info("machine [%s] has reached current plan limit of %s. Shutting down...",
		bm.IpAddress, usg.InactiveDuration)

	// Hasta la vista, baby!
	q.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", bm.ObjectId.Hex())

	meta, err := m.Stop(ctx)
	if err != nil {
		// returning is ok, because Kloud will mark it anyways as stopped if
		// Klient is not rechable anymore with the `info` method
		q.Log.Info("[%s] ======> STOP aborted (closing inactive machine: %s)<======", bm.ObjectId.Hex(), err)

		return err
	}

	q.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", bm.ObjectId.Hex())

	obj := object.MetaBuilder.Build(meta)
	obj["status.modifiedAt"] = time.Now().UTC()
	obj["status.state"] = machinestate.Stopped.String()
	obj["status.reason"] = "Machine is stopped due to inactivity"

	return modelhelper.UpdateMachine(bm.ObjectId, bson.M{"$set": obj})
}
