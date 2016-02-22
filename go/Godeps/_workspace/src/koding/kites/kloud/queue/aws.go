package queue

import (
	"errors"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/provider/aws"
	"time"

	"golang.org/x/net/context"

	"github.com/koding/kite"
	"github.com/koding/kite/kontrol"
	"gopkg.in/mgo.v2"
)

func (q *Queue) CheckAWS() {
	var machine awsprovider.Machine
	err := q.FetchProvider("aws", &machine.Machine)
	if err != nil {
		// do not show an error if the query didn't find anything, that
		// means there is no such a document, which we don't care
		if err != mgo.ErrNotFound {
			q.Log.Warning("FetchOne AWS err: %v", err)
		}

		// move one with the next one
		return
	}

	if err := q.CheckAWSUsage(&machine); err != nil {
		// only log if it's something else
		switch err {
		case kite.ErrNoKitesAvailable,
			kontrol.ErrQueryFieldsEmpty,
			klient.ErrDialingFailed:
		default:
			q.Log.Debug("[%s] check usage of AWS klient kite [%s] err: %v",
				machine.ObjectId.Hex(), machine.IpAddress, err)
		}
	}
}

func (q *Queue) CheckAWSUsage(m *awsprovider.Machine) error {
	q.Log.Debug("Checking AWS machine\n%+v\n", m)
	if m == nil {
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
	if err := q.AwsProvider.AttachSession(ctx, m); err != nil {
		return err
	}

	klientRef, err := klient.Connect(m.Session.Kite, m.QueryString)
	if err != nil {
		m.Log.Debug("Error connecting to klient, stopping if needed. Error: %s",
			err.Error())
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
