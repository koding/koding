package provider

import (
	"errors"
	"fmt"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan/stackcred"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// All is a global lookup map used ny kloud to register
// available stack providers.
var All = make(map[string]func(*BaseProvider) stack.Provider)

// BaseProvider implements common functionality for stack providers (aws, vagrant).
//
// In longer term kloud controllers should be refactored and this functionality
// moved there, so stack providers can be more thin. Another todo is to
// merge common apply/destroy methods for each provider, so each provider
// implements only extra provider-specific logic for building stackplan.
//
// TODO(rjeczalik): rework all external dependencies like Logger, Kite, DB etc.
// in *BaseProvider, *BaseStack, *BaseMachine, *stackplan.Builder
// and *session.Session into single *kloud.Context struct built in main.go
// and pass it down all code paths. To eliminate duplication.
type BaseProvider struct {
	Name           string
	DB             *mongodb.MongoDB
	Log            logging.Logger
	Kite           *kite.Kite
	KloudSecretKey string
	Debug          bool
	TunnelURL      string

	Userdata  *userdata.Userdata
	CredStore stackcred.Store
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
		return nil, stack.NewError(stack.ErrMachineNotFound)
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
			DB:       bp.DB,
			Kite:     bp.Kite,
			Userdata: bp.Userdata,
			Log:      bp.Log.New(m.ObjectId.Hex()),
		},
		Req:      req,
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

		if err := bp.ValidateUser(bm.User, bm.Users, req); err != nil {
			return nil, err
		}
	}

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		bm.Log = logging.NewCustom("kloud-"+bp.Name, true).New(m.ObjectId.Hex()).New(traceID)
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

func (bp *BaseProvider) FetchCredData(bm *BaseMachine, data interface{}) error {
	return bp.CredStore.Fetch(bm.Username(), map[string]interface{}{bm.Credential: data})
}

func (bp *BaseProvider) ValidateUser(user *models.User, users []models.MachineUser, r *kite.Request) error {
	// give access to kloudctl immediately
	if stack.IsKloudctlAuth(r, bp.KloudSecretKey) {
		return nil
	}

	if r.Username != user.Name {
		return errors.New("username is not permitted to make any action")
	}

	// check for user permissions
	if err := checkUser(user.ObjectId, users); err != nil {
		return err
	}

	if user.Status != "confirmed" {
		return stack.NewError(stack.ErrUserNotConfirmed)
	}

	return nil
}

// checkUser checks whether the given username is available in the users list
// and has permission
func checkUser(userId bson.ObjectId, users []models.MachineUser) error {
	// check if the incoming user is in the list of permitted user list
	for _, u := range users {
		if userId == u.Id && (u.Owner || (u.Permanent && u.Approved)) {
			return nil // ok he/she is good to go!
		}
	}

	return fmt.Errorf("permission denied. user not in the list of permitted users")
}
