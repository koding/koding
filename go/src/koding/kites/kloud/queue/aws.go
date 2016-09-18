package queue

import (
	"koding/db/models"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/provider/oldaws"
	"time"

	"golang.org/x/net/context"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"gopkg.in/mgo.v2"
)

func (q *Queue) CheckAWS() {
	if q.AwsProvider == nil {
		return
	}

	m := &oldaws.Machine{
		BaseMachine: &provider.BaseMachine{
			Machine: &models.Machine{},
		},
	}
	err := q.FetchProvider("aws", m.Machine)
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne AWS err: %v", err)
		}

		// move one with the next one
		return
	}

	if err := q.CheckAWSUsage(m); err != nil {
		// only log if it's something else
		switch err {
		case kite.ErrNoKitesAvailable,
			kontrol.ErrQueryFieldsEmpty,
			klient.ErrDialingFailed:
		default:
			q.Log.Debug("[%s] check usage of AWS klient kite [%s] err: %v",
				m.ObjectId.Hex(), m.IpAddress, err)
		}
	}
}

func (q *Queue) AttachSession(m *oldaws.Machine) (*oldaws.Machine, context.Context, error) {
	req := &kite.Request{
		Method: "internal",
	}

	if u := m.Owner(); u != nil {
		req.Username = u.Username
	}

	ctx := request.NewContext(context.Background(), req)
	builtM, err := q.AwsProvider.Machine(ctx, m.ObjectId.Hex())
	if err != nil {
		return nil, nil, err
	}

	return builtM.(*oldaws.Machine), ctx, nil
}

func (q *Queue) CheckAWSUsage(m *oldaws.Machine) error {
	m, ctx, err := q.AttachSession(m)
	if err != nil {
		return err
	}

	q.Log.Debug("Checking AWS machine\n%+v\n", m)

	klientRef, err := klient.Connect(m.Session.Kite, m.QueryString)
	if err != nil {
		m.Log.Debug("Error connecting to klient, stopping if needed. Error: %s",
			err.Error())
		return err
	}

	// replace with the real and authenticated username
	if m.User == nil {
		m.User = &models.User{}
	}
	m.User.Name = klientRef.Username

	// get the usage directly from the klient, which is the most predictable source
	usg, err := klientRef.Usage()

	// close the underlying connection once we get the usage
	klientRef.Close()
	klientRef = nil
	if err != nil {
		m.Log.Debug("Error getting klient usage, stopping if needed. Error: %s",
			err.Error())
		return err
	}

	// we don't have any payments for AWS. Assume the timeout is the same as
	// for Koding, 50 minutes
	planTimeout := 50 * time.Minute

	q.Log.Debug("machine [%s] (aws) is inactive for %s (plan limit: %s)",
		m.IpAddress, usg.InactiveDuration, planTimeout)

	// It still have plenty of time to work, do not stop it
	if usg.InactiveDuration <= planTimeout {
		return nil
	}

	q.Log.Info("machine [%s] has reached current plan limit of %s. Shutting down...",
		m.IpAddress, usg.InactiveDuration)

	// Hasta la vista, baby!
	q.Log.Info("[%s] ======> STOP started (closing inactive machine)<======", m.ObjectId.Hex())
	if err := m.Stop(ctx); err != nil {
		// returning is ok, because Kloud will mark it anyways as stopped if
		// Klient is not rechable anymore with the `info` method
		q.Log.Info("[%s] ======> STOP aborted (closing inactive machine: %s)<======", m.ObjectId.Hex(), err)
		return err
	}

	q.Log.Info("[%s] ======> STOP finished (closing inactive machine)<======", m.ObjectId.Hex())
	return nil
}
