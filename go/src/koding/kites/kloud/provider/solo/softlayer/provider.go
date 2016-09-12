package softlayer

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/userdata"
	"strings"
	"time"

	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

var (
	defaultKlientTimeout = 15 * time.Minute
	defaultStateTimeout  = 15 * time.Minute

	// We choose WASHINGTON 04 because it works
	// http://www.softlayer.com/data-centers
	defaultDatacenter = "wdc04"
)

type Provider struct {
	DB            *mongodb.MongoDB
	Log           logging.Logger
	Kite          *kite.Kite
	SLClient      *sl.Softlayer
	DNSClient     *dnsclient.Route53
	DNSStorage    *dnsstorage.MongodbStorage
	Userdata      *userdata.Userdata
	KlientTimeout time.Duration
	StateTimeout  time.Duration
	Base          *provider.BaseProvider
}

type slCred struct {
	Username string `mapstructure:"username"`
	ApiKey   string `mapstructure:"api_key"`
}

func (p *Provider) Machine(ctx context.Context, id string) (interface{}, error) {
	if !bson.IsObjectIdHex(id) {
		return nil, fmt.Errorf("Invalid machine id: %q", id)
	}

	// let's first check if the id exists, because we are going to use
	// findAndModify() and it would be difficult to distinguish if the id
	// really doesn't exist or if there is an assignee which is a different
	// thing. (Because findAndModify() also returns "not found" for the case
	// where the id exist but someone else is the assignee).
	machine := &Machine{}
	if err := p.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine.Machine)
	}); err == mgo.ErrNotFound {
		return nil, stack.NewError(stack.ErrMachineNotFound)
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	meta, err := machine.GetMeta()
	if err != nil {
		return nil, err
	}

	if meta.Datacenter == "" {
		machine.Meta["datacenter"] = defaultDatacenter
		p.Log.Warning("[%s] datacenter is not set; falling back to %s", machine.ObjectId.Hex(), defaultDatacenter)
	}

	// Ensure the domain is rooted at the hosted zone.
	if !strings.HasSuffix(machine.Domain, p.DNSClient.HostedZone()) {
		machine.Domain = machine.Uid + "." + machine.Credential + "." + p.DNSClient.HostedZone()
	}

	p.Log.Debug("Using datacenter=%q, image=%q", meta.Datacenter, meta.SourceImage)

	if err := p.AttachSession(ctx, machine); err != nil {
		return nil, err
	}

	// check for validation and permission
	if err := p.Base.ValidateUser(machine.User, machine.Users, req); err != nil {
		return nil, err
	}

	machine.KlientTimeout = p.klientTimeout()
	machine.StateTimeout = p.stateTimeout()

	return machine, nil
}

func (p *Provider) AttachSession(ctx context.Context, machine *Machine) error {
	// get user model which contains user ssh keys or the list of users that
	// are allowed to use this machine
	if len(machine.Users) == 0 {
		return errors.New("permitted users list is empty")
	}

	// check if this is called via Kite call
	var requesterName string
	req, ok := request.FromContext(ctx)
	if ok {
		requesterName = req.Username
	}

	// get the user from the permitted list. If the list contains more than one
	// allowed person, fetch the one that is the same as requesterName, if
	// not pick up the first one.
	user, err := modelhelper.GetPermittedUser(requesterName, machine.Users)
	if err != nil {
		return err
	}

	// attach user specific log
	machine.Log = p.Log.New(machine.ObjectId.Hex())

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		machine.Log = logging.NewCustom("kloud-softlayer", true).New(machine.ObjectId.Hex()).New(traceID)
	}

	sess := &session.Session{
		DB:         p.DB,
		Kite:       p.Kite,
		DNSClient:  p.DNSClient,
		DNSStorage: p.DNSStorage,
		Userdata:   p.Userdata,
		SLClient:   p.SLClient,
		Log:        machine.Log,
	}

	// we use session a lot of in Machine owned methods, so that's why we
	// assign it to a field for easy access
	machine.Session = sess

	// we pass it also to the context, so other packages, such as plans
	// checker can make use of it.
	ctx = session.NewContext(ctx, sess)

	machine.Username = user.Name
	machine.User = user

	ev, ok := eventer.FromContext(ctx)
	if ok {
		machine.Session.Eventer = ev
	}

	return nil
}

// getUserCredential fetches the credential for the given identifier. This is
// not used right now, but will be used once we decide to give custom softlayer
// instances
func (p *Provider) getUserCredential(identifier string) (*slCred, error) {
	creds, err := modelhelper.GetCredentialDatasFromIdentifiers(identifier)
	if err != nil {
		return nil, fmt.Errorf("could not fetch credential %q: %s", identifier, err.Error())
	}

	if len(creds) == 0 {
		return nil, fmt.Errorf("softlayer: no credential data available for credential: %s", identifier)
	}

	c := creds[0] // there is only one, pick up the first one

	var cred slCred
	if err := mapstructure.Decode(c.Meta, &cred); err != nil {
		return nil, err
	}

	if structs.HasZero(cred) {
		return nil, fmt.Errorf("softlayer data is incomplete: %v", c.Meta)
	}

	return &cred, nil
}

func (p *Provider) klientTimeout() time.Duration {
	if p.KlientTimeout != 0 {
		return p.KlientTimeout
	}
	return defaultKlientTimeout
}

func (p *Provider) stateTimeout() time.Duration {
	if p.StateTimeout != 0 {
		return p.StateTimeout
	}
	return defaultStateTimeout
}
