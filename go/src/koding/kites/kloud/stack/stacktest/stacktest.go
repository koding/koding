package stacktest

import (
	"encoding/json"
	"fmt"
	"net/url"

	"koding/api"
	"koding/kites/kloud/stack"
	"koding/remoteapi"

	"github.com/koding/kite"
	"github.com/koding/kite/dnode"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

// CLEANUP(rjeczalik): The following packages should be merged into one:
//
//   - kloud/stack
//   - kloud/stack/provider
//   - kloud/kloud
//
// To fix Base* types abstraction leak and also simplify types, control flow
// and enable testing of the kloud server.

// DefaultLog is a default logger used in FakeKloud.
var DefaultLog = logging.NewCustom("stacktest", true)

// NewRequest mocks new kite.Request for the following arguments.
func NewRequest(method, username string, arg interface{}) *kite.Request {
	p, err := json.Marshal([]interface{}{arg})
	if err != nil {
		panic(fmt.Errorf("unexpected error marshaling %T: %s", arg, err))
	}

	r := &kite.Request{
		Method:   method,
		Username: username,
		Args: &dnode.Partial{
			Raw: p,
		},
	}

	return r
}

// SpyStacker provides a stack.Stacker implementation that records
// all calls to Handle* methods.
type SpyStacker struct {
	Apply     []*stack.ApplyRequest
	Auth      []*stack.AuthenticateRequest
	Bootstrap []*stack.BootstrapRequest
	Plan      []*stack.PlanRequest
}

var (
	_ stack.Stacker  = (*SpyStacker)(nil)
	_ stack.Provider = (*SpyStacker)(nil)
)

func (*SpyStacker) VerifyCredential(*stack.Credential) error { return nil }
func (*SpyStacker) BootstrapTemplates(*stack.Credential) ([]*stack.Template, error) {
	return nil, nil
}
func (*SpyStacker) ApplyTemplate(*stack.Credential) (*stack.Template, error) { return nil, nil }
func (ss *SpyStacker) Stack(context.Context) (interface{}, error)            { return ss, nil }
func (*SpyStacker) Machine(context.Context, string) (interface{}, error)     { return nil, nil }
func (*SpyStacker) NewCredential() interface{}                               { return nil }
func (*SpyStacker) NewBootstrap() interface{}                                { return nil }

// HandleApply implements the stack.Stacker interface.
func (ss *SpyStacker) HandleApply(ctx context.Context) (interface{}, error) {
	if req, ok := ctx.Value(stack.ApplyRequestKey).(*stack.ApplyRequest); ok {
		ss.Apply = append(ss.Apply, req)
	}

	return &stack.ControlResult{
		EventId: "mocked-event-id",
	}, nil
}

// HandleAuthenticate implements the stack.Stacker interface.
func (ss *SpyStacker) HandleAuthenticate(ctx context.Context) (interface{}, error) {
	if req, ok := ctx.Value(stack.AuthenticateRequestKey).(*stack.AuthenticateRequest); ok {
		ss.Auth = append(ss.Auth, req)
	}

	return make(map[string]*stack.AuthenticateResult), nil
}

// HandleBootstrap implements the stack.Stacker interface.
func (ss *SpyStacker) HandleBootstrap(ctx context.Context) (interface{}, error) {
	if req, ok := ctx.Value(stack.BootstrapRequestKey).(*stack.BootstrapRequest); ok {
		ss.Bootstrap = append(ss.Bootstrap, req)
	}

	return true, nil
}

// HandlePlan implements the stack.Stacker interface.
func (ss *SpyStacker) HandlePlan(ctx context.Context) (interface{}, error) {
	if req, ok := ctx.Value(stack.PlanRequestKey).(*stack.PlanRequest); ok {
		ss.Plan = append(ss.Plan, req)
	}

	return make(stack.Machines), nil
}

// FakeKloud mocks stack.Kloud value, so it can be used
// safely in unittests.
//
// This is a best-effort attempt of providing a fake,
// it is not a general purpose fake - it may be not
// suitable for certain use-cases without further
// refactoring.
type FakeKloud struct {
	*stack.Kloud
	Stacker SpyStacker
}

// NewFakeKloud gives new FakeKloud value.
func NewFakeKloud(remoteapiURL string) *FakeKloud {
	u, err := url.Parse(remoteapiURL)
	if err != nil || remoteapiURL == "" {
		u = &url.URL{
			Scheme: "http",
			Host:   "127.0.0.1",
		}
	}

	fk := &FakeKloud{
		Kloud: stack.New(),
	}

	fk.Kloud.Log = DefaultLog
	fk.Kloud.AddProvider("test", &fk.Stacker)
	fk.Kloud.NewStack = func(*kite.Request, *stack.TeamRequest) (stack.Stacker, context.Context, error) {
		return &fk.Stacker, context.Background(), nil
	}
	fk.Kloud.RemoteClient = &remoteapi.Client{
		Endpoint: u,
		Transport: &api.Transport{
			AuthFunc: func(opts *api.AuthOptions) (*api.Session, error) {
				return &api.Session{
					ClientID: "mocked-client-id",
					User:     opts.User,
				}, nil
			},
			Log:   DefaultLog,
			Debug: true,
		},
	}

	return fk
}
