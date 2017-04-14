package provider

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
	"koding/kites/kloud/credential"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/userdata"
	"koding/kites/kloud/utils/object"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// TODO(rjeczalik): remove context.Context from the Provider / Stack / Machine API,
// which is a leftover from the old API - it was errornously designed to
// store global-scoped values.

// Stacker is responsible for augmenting Provider values so they implement
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
	Environment    string
	TunnelURL      string

	Userdata  *userdata.Userdata
	SSHKey    *publickeys.Keys
	CredStore credential.Store
}

func (s *Stacker) New(p *Provider) *Stacker {
	sCopy := *s
	sCopy.Provider = p
	sCopy.Log = sCopy.Log.New(p.Name)

	return &sCopy
}

func (s *Stacker) NewCredential() interface{} {
	return s.Provider.newCredential()
}

func (s *Stacker) NewBootstrap() interface{} {
	return s.Provider.newBootstrap()
}

func (s *Stacker) Machine(ctx context.Context, id string) (interface{}, error) {
	bm, err := s.BaseMachine(ctx, id)
	if err != nil {
		return nil, err
	}

	return s.BuildMachine(ctx, bm)
}

func (s *Stacker) BuildMachine(ctx context.Context, bm *BaseMachine) (Machine, error) {
	if err := modelhelper.BsonDecode(bm.Meta, object.ToAddr(bm.Metadata)); err != nil {
		return nil, err
	}

	if v, ok := bm.Metadata.(stack.Validator); ok {
		if err := v.Valid(); err != nil {
			return nil, err
		}
	}

	if err := s.FetchCredData(bm); err != nil {
		return nil, err
	}

	s.Log.Debug("credential: %# v, bootstrap: %# v", bm.Credential, bm.Bootstrap)

	m, err := s.Provider.Machine(bm)
	if err != nil {
		return nil, err
	}

	bm.machine = m

	return m, nil
}

func (s *Stacker) BaseMachine(ctx context.Context, id string) (*BaseMachine, error) {
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

	return s.BuildBaseMachine(ctx, m)
}

func (s *Stacker) BuildBaseMachine(ctx context.Context, m *models.Machine) (*BaseMachine, error) {
	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	bm := &BaseMachine{
		Machine: m,
		Session: &session.Session{
			DB:       s.DB,
			Kite:     s.Kite,
			Userdata: s.Userdata,
			Log:      s.Log.New(m.ObjectId.Hex()),
		},
		Credential: s.Provider.newCredential(),
		Bootstrap:  s.Provider.newBootstrap(),
		Metadata:   s.Provider.newMetadata(nil),
		Req:        req,
		Provider:   s.Provider.Name,
		Debug:      s.Debug,
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
		var err error
		bm.User, err = modelhelper.GetPermittedUser(req.Username, bm.Users)
		if err != nil {
			return nil, err
		}

		if err := s.ValidateUser(bm.User, bm.Users, req); err != nil {
			return nil, err
		}
	}

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		bm.Log = logging.NewCustom("kloud-"+s.Provider.Name, true).New(m.ObjectId.Hex()).New(traceID)
		bm.Debug = true
		bm.TraceID = traceID
	}

	ev, ok := eventer.FromContext(ctx)
	if ok {
		bm.Eventer = ev
	}

	s.Log.Debug("BaseMachine: %+v", bm)

	return bm, nil
}

func (b *Stacker) Stack(ctx context.Context) (interface{}, error) {
	bs, err := b.BaseStack(ctx)
	if err != nil {
		return nil, err
	}

	s, err := b.Provider.Stack(bs)
	if err != nil {
		return nil, err
	}

	bs.stack = s

	return s, nil
}

// BaseStack builds new base stack for the given context value.
func (s *Stacker) BaseStack(ctx context.Context) (*BaseStack, error) {
	bs := &BaseStack{
		Planner: &Planner{
			Provider:     s.Provider.Name,
			ResourceType: s.Provider.resourceName(),
			Log:          s.Log,
		},
		Provider:  s.Provider,
		KlientIDs: make(stack.KiteMap),
		Klients:   make(map[string]*DialState),
		Metas:     make(map[string]map[string]interface{}),
		TunnelURL: s.TunnelURL,
		Keys:      s.SSHKey,
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

	if err := bs.Builder.BuildTeam(req.GroupName); err != nil {
		return nil, err
	}

	if !bs.Builder.Team.IsSubActive(s.Environment) {
		return nil, stack.NewError(stack.ErrTeamSubIsNotActive)
	}

	return bs, nil
}

func (s *Stacker) FetchCredData(bm *BaseMachine) error {
	credentials := make(map[string]interface{})

	if bm.Bootstrap != nil {
		credentials[bm.Machine.Credential] = object.Inline(bm.Credential, bm.Bootstrap)
	} else {
		credentials[bm.Machine.Credential] = object.ToAddr(bm.Credential)
	}

	return s.CredStore.Fetch(bm.Username(), credentials)
}

func (s *Stacker) ValidateUser(user *models.User, users []models.MachineUser, r *kite.Request) error {
	// give access to kloudctl immediately
	if stack.IsKloudSecretAuth(r, s.KloudSecretKey) {
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

func (bm *BaseMachine) WaitKlientReady(timeout time.Duration) (*DialState, error) {
	bm.Log.Debug("testing for %s (%s) klient kite connection", bm.QueryString, bm.IpAddress)

	if timeout <= 0 {
		timeout = bm.klientTimeout()
	}

	state := (&Planner{
		KlientTimeout: timeout,
		Log:           bm.Log,
	}).checkSingleKlient(bm.Kite, bm.Label, bm.QueryString)

	if state.Err != nil {
		return nil, &DialError{
			States: []*DialState{state},
		}
	}

	return state, nil
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

func (bm *BaseMachine) PushError(err error, state machinestate.State) {
	if bm.Eventer != nil {
		bm.Eventer.Push(&eventer.Event{
			Percentage: 100,
			Status:     state,
			Error:      err.Error(),
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
