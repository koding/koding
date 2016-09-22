package stackplan

import (
	"errors"
	"fmt"
	"time"

	"koding/db/models"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan/stackcred"
	"koding/kites/kloud/userdata"
	"koding/kites/kloud/utils/object"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// TODO(rjeczalik): remove context.Context from the Provider / Stack / Machine API,
// which is a leftover from the old API - it was errornously desgined to
// store global-scoped values.

// Stacker is responsible for augementing Provider values so they implement
// Stack and Machine interfaces.
//
// In longer term kloud controllers should be refactored and this functionality
// moved there, so stack providers can be more thin. Another todo is to
// merge common apply/destroy methods for each provider, so each provider
// implements only extra provider-specific logic for building stackplan.
//
// TODO(rjeczalik): rework all external dependencies like Logger, Kite, DB etc.
// in *Stacker, *BaseStack, *BaseMachine, *stackplan.Stacker
// and *session.Session into single *kloud.Context struct built in main.go
// and pass it down all code paths. To eliminate duplication.
type Stacker struct {
	Provider *Provider

	DB             *mongodb.MongoDB
	Log            logging.Logger
	Kite           *kite.Kite
	KloudSecretKey string
	Debug          bool

	Userdata  *userdata.Userdata
	CredStore stackcred.Store
}

func (b *Stacker) New(p *Provider) *Stacker {
	bCopy := *b
	bCopy.Provider = p
	bCopy.Log = bCopy.Log.New(p.Name)

	return &bCopy
}

func (b *Stacker) Machine(ctx context.Context, id string) (Machine, error) {
	bm, err := b.BaseMachine(ctx, id)
	if err != nil {
		return nil, err
	}

	if err := modelhelper.BsonDecode(bm.Meta, object.ToAddr(bm.Metadata)); err != nil {
		return nil, err
	}

	if v, ok := bm.Metadata.(stack.Validator); ok {
		if err := v.Valid(); err != nil {
			return nil, err
		}
	}

	if err := b.FetchCredData(bm); err != nil {
		return nil, err
	}

	b.Log.Debug("credential: %# v, bootstrap: %# v", bm.Credential, bm.Bootstrap)

	return b.Provider.NewMachine(bm)
}

func (b *Stacker) BaseMachine(ctx context.Context, id string) (*BaseMachine, error) {
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
			DB:       b.DB,
			Kite:     b.Kite,
			Userdata: b.Userdata,
			Log:      b.Log.New(m.ObjectId.Hex()),
		},
		Credential: b.Provider.newCredential(),
		Bootstrap:  b.Provider.newBootstrap(),
		Metadata:   b.Provider.newMetadata(),
		Req:        req,
		Provider:   b.Provider.Name,
		Debug:      b.Debug,
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

		if err := b.ValidateUser(bm.User, bm.Users, req); err != nil {
			return nil, err
		}
	}

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		bm.Log = logging.NewCustom("kloud-"+b.Provider.Name, true).New(m.ObjectId.Hex()).New(traceID)
		bm.Debug = true
		bm.TraceID = traceID
	}

	ev, ok := eventer.FromContext(ctx)
	if ok {
		bm.Eventer = ev
	}

	b.Log.Debug("BaseMachine: %+v", bm)

	return bm, nil
}

func (b *Stacker) Stack(ctx context.Context) (Stack, error) {
	bs, err := b.BaseStack(ctx)
	if err != nil {
		return nil, err
	}

	s, err := b.Provider.NewStack(bs)
	if err != nil {
		return nil, err
	}

	if bs.Stack == nil {
		bs.Stack = s
	}

	return s, nil
}

// BaseStack builds new base stack for the given context value.
func (s *Stacker) BaseStack(ctx context.Context) (*BaseStack, error) {
	bs := &BaseStack{
		Planner: &Planner{
			Provider:     s.Provider.Name,
			ResourceType: s.Provider.resourceName(),
		},
		Provider:  s.Provider,
		KlientIDs: make(stack.KiteMap),
		Klients:   make(map[string]*DialState),
	}

	var ok bool
	if bs.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	req, ok := stack.TeamRequestFromContext(ctx)
	if !ok {
		return nil, errors.New("team request not available in context")
	}

	if bs.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	bs.Log = s.Log.New(req.GroupName)

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		bs.Log = logging.NewCustom("kloud-"+req.Provider, true).New(traceID)
		bs.TraceID = traceID
	}

	if keys, ok := publickeys.FromContext(ctx); ok {
		bs.Keys = keys
	}

	if ev, ok := eventer.FromContext(ctx); ok {
		bs.Eventer = ev
	}

	builderOpts := &BuilderOptions{
		Log:       s.Log.New("stackplan"),
		CredStore: s.CredStore,
	}

	bs.Builder = NewBuilder(builderOpts)

	return bs, nil
}

func (s *Stacker) FetchCredData(bm *BaseMachine) error {
	credentials := make(map[string]interface{})

	if bm.Bootstrap == nil {
		credentials[bm.Machine.Credential] = bm.Credential
	} else {
		credentials[bm.Machine.Credential] = object.Inline(bm.Credential, bm.Bootstrap)
	}

	return s.CredStore.Fetch(bm.Username(), credentials)
}

func (s *Stacker) ValidateUser(user *models.User, users []models.MachineUser, r *kite.Request) error {
	// give access to kloudctl immediately
	if stack.IsKloudctlAuth(r, s.KloudSecretKey) {
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

func (bm *BaseMachine) ProviderName() string {
	return bm.Provider
}

// Username gives name of user that owns the machine or requested an
// action on the machine.
func (bm *BaseMachine) Username() string {
	if bm.User != nil {
		return bm.User.Name
	}

	return bm.Req.Username
}

// State returns the machinestate of the machine.
func (bm *BaseMachine) State() machinestate.State {
	return machinestate.States[bm.Status.State]
}

func (bm *BaseMachine) WaitKlientReady() error {
	bm.Log.Debug("testing for %s (%s) klient kite connection", bm.QueryString, bm.IpAddress)

	c, err := klient.NewWithTimeout(bm.Kite, bm.QueryString, bm.klientTimeout())
	if err != nil {
		return fmt.Errorf("connection test for %s (%s) klient error: %s", bm.QueryString, bm.IpAddress, err)
	}
	defer c.Close()

	if err := c.Ping(); err != nil {
		return fmt.Errorf("pinging %s (%s) klient error: %s", bm.QueryString, bm.IpAddress, err)
	}

	return nil
}

func (bm *BaseMachine) PushEvent(msg string, percentage int, state machinestate.State) {
	if bm.Eventer != nil {
		bm.Eventer.Push(&eventer.Event{
			Message:    msg,
			Percentage: percentage,
			Status:     state,
		})
	}
}

func (bm *BaseMachine) klientTimeout() time.Duration {
	if bm.KlientTimeout != 0 {
		return bm.KlientTimeout
	}

	return DefaultKlientTimeout
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
