package vagrant

import (
	"errors"
	"fmt"
	"net/url"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	"koding/kites/kloud/api/vagrantapi"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider/helpers"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// TODO(rjeczalik): kloud refactoring notes:
//
//   - create provider.BaseProvider, provider.BaseMachine
//     complementary to existing provider.BaseStack
//   - create provider.MetaFunc for custom machine metadata handling
//   - create modelhelpers.DB and move function helpers to methods,
//     so it's posible to use it with non-global *mongodb.MongoDB
//     values
//

// Provider implements machine management operations.
type Provider struct {
	DB         *mongodb.MongoDB
	Log        logging.Logger
	Kite       *kite.Kite
	DNSClient  *dnsclient.Route53
	DNSStorage *dnsstorage.MongodbStorage
	Userdata   *userdata.Userdata
	TunnelURL  string
	Debug      bool
}

func (p *Provider) Machine(ctx context.Context, id string) (interface{}, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	machine, err := modelhelper.GetMachine(id)
	if err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}
	if err != nil {
		return nil, errors.New("unable to get machine: " + err.Error())
	}
	m := &Machine{
		Machine: machine,
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	meta, err := m.GetMeta()
	if err != nil {
		return nil, errors.New("unable to get meta: +" + err.Error())
	}

	m.Meta = meta

	if err := p.AttachSession(ctx, m); err != nil {
		return nil, err
	}

	if err := helpers.ValidateUser(m.User, m.Users, req); err != nil {
		return nil, err
	}

	return m, nil
}

func (p *Provider) AttachSession(ctx context.Context, m *Machine) error {
	if len(m.Users) == 0 {
		return errors.New("permitted users list is empty")
	}

	var reqUser string
	req, ok := request.FromContext(ctx)
	if ok {
		reqUser = req.Username
	}

	user, err := modelhelper.GetPermittedUser(reqUser, m.Users)
	if err != nil {
		return err
	}

	m.User = user
	m.Log = p.Log.New(m.ObjectId.Hex())

	debug := p.Debug
	if traceID, ok := kloud.TraceFromContext(ctx); ok {
		m.Log = common.NewLogger("kloud-vagrant", true).New(m.ObjectId.Hex()).New(traceID)
		debug = true
	}

	m.Session = &session.Session{
		DB:         p.DB,
		Kite:       newKite(p.Kite), // TODO(rjeczalik): remove after TMS-2245 and use p.Kite directly
		DNSClient:  p.DNSClient,
		DNSStorage: p.DNSStorage,
		Userdata:   p.Userdata,
		Log:        m.Log,
	}

	m.api = &vagrantapi.Klient{
		Kite:  p.Kite,
		Log:   m.Log.New("vagrantapi"),
		Debug: debug,
	}

	ev, ok := eventer.FromContext(ctx)
	if ok {
		m.Session.Eventer = ev
	}

	return nil
}

func (p *Provider) tunnelURL() (*url.URL, error) {
	if p.TunnelURL == "" {
		return nil, errors.New("no tunnel URL provided")
	}

	u, err := url.Parse(p.TunnelURL)
	if err != nil {
		return nil, err
	}

	u.Path = "/kite"

	return u, nil
}
