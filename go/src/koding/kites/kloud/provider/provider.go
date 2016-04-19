package provider

import (
	"errors"
	"fmt"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider/helpers"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

type BaseProvider struct {
	Name  string
	DB    *mongodb.MongoDB
	Log   logging.Logger
	Kite  *kite.Kite
	Debug bool

	DNSClient  *dnsclient.Route53
	DNSStorage *dnsstorage.MongodbStorage
	Userdata   *userdata.Userdata
	CredStore  stackplan.CredStore
}

func (bp *BaseProvider) New(name string) *BaseProvider {
	bpCopy := *bp
	bpCopy.Name = name
	bpCopy.Log = bpCopy.Log.New(name)

	return &bpCopy
}

func (bp *BaseProvider) BaseMachine(ctx context.Context, id string) (*BaseMachine, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("invalid machine id: %q", id)
	}

	m, err := modelhelper.GetMachine(id)
	if err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}
	if err != nil {
		return nil, fmt.Errorf("unable to get machine: %s", err)
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	bm := &BaseMachine{
		Machine: m,
		Session: &session.Session{
			DB:         bp.DB,
			Kite:       bp.Kite,
			DNSClient:  bp.DNSClient,
			DNSStorage: bp.DNSStorage,
			Userdata:   bp.Userdata,
			Log:        bp.Log.New(m.ObjectId.Hex()),
		},
		Provider: bp.Name,
		Debug:    bp.Debug,
	}

	// NOTE(rjeczalik): "internal" method is used by (*Queue).CheckAWS
	if req.Method != "internal" {
		// get user model which contains user ssh keys or the list of users that
		// are allowed to use this machine
		if len(m.Users) == 0 {
			return nil, errors.New("permitted users list is empty")
		}

		// get the user from the permitted list. If the list contains more than one
		// allowed person, fetch the one that is the same as requesterName, if
		// not pick up the first one.
		bm.User, err = modelhelper.GetPermittedUser(req.Username, bm.Users)
		if err != nil {
			return nil, err
		}

		if err := helpers.ValidateUser(bm.User, bm.Users, req); err != nil {
			return nil, err
		}
	}

	if traceID, ok := kloud.TraceFromContext(ctx); ok {
		bm.Log = common.NewLogger("kloud-"+bp.Name, true).New(m.ObjectId.Hex()).New(traceID)
		bm.Debug = true
		bm.TraceID = traceID
	}

	ev, ok := eventer.FromContext(ctx)
	if ok {
		bm.Eventer = ev
	}

	bp.Log.Debug("BaseMachine: %+v", bm)

	return bm, nil
}
