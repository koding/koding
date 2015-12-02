package softlayer

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider/helpers"
	"koding/kites/kloud/userdata"

	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"

	"golang.org/x/net/context"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/maximilien/softlayer-go/softlayer"
)

// DefaultImageID is a standard image template for sjc01 region.
//
// TODO(rjeczalik): this is going to be replaced by querying
// Softlayer for image tagged production / testing depending
// on the env kloud is started in (cmd line switch).
const DefaultImageID = "a2f93d90-5df9-44ee-afb2-931a98186836"

type Provider struct {
	DB         *mongodb.MongoDB
	Log        logging.Logger
	Kite       *kite.Kite
	SLClient   softlayer.Client
	DNSClient  *dnsclient.Route53
	DNSStorage *dnsstorage.MongodbStorage
	Userdata   *userdata.Userdata
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
		return c.FindId(bson.ObjectIdHex(id)).One(&machine)
	}); err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
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
		// We choose DALLAS 01 because it has the largest capacity
		// http://www.softlayer.com/data-centers
		machine.Meta["datacenter"] = "sjc01"
		p.Log.Critical("[%s] datacenter is not set in. Fallback to sjc01", machine.ObjectId.Hex())
	}

	if meta.SourceImage == "" {
		meta.SourceImage = DefaultImageID
		p.Log.Critical("[%s] image template ID is not set, using default one: %q",
			machine.ObjectId.Hex(), DefaultImageID)
	}

	p.Log.Debug("Using datacenter=%q, image=%q", meta.Datacenter, meta.SourceImage)

	if err := p.AttachSession(ctx, machine); err != nil {
		return nil, err
	}

	// check for validation and permission
	if err := helpers.ValidateUser(machine.User, machine.Users, req); err != nil {
		return nil, err
	}

	return machine, nil
}

func (p *Provider) AttachSession(ctx context.Context, machine *Machine) error {
	// get user model which contains user ssh keys or the list of users that
	// are allowed to use this machine
	if len(machine.Users) == 0 {
		return errors.New("permitted users list is empty")
	}

	user, err := modelhelper.GetOwner(machine.Users)
	if err != nil {
		return err
	}

	// attach user specific log
	machine.Log = p.Log.New(machine.ObjectId.Hex())

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
