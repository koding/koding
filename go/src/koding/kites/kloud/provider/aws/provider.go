package awsprovider

import (
	"errors"
	"fmt"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
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
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/mapstructure"
	"golang.org/x/net/context"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type Provider struct {
	DB         *mongodb.MongoDB
	Log        logging.Logger
	Kite       *kite.Kite
	DNSClient  *dnsclient.Route53
	DNSStorage *dnsstorage.MongodbStorage
	Userdata   *userdata.Userdata
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

	if machine.Meta.Region == "" {
		return nil, errors.New("region is not set")
	}

	p.Log.Debug("Using region: %s", machine.Meta.Region)

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

	creds, err := modelhelper.GetCredentialDatasFromIdentifiers(machine.Credential)
	if err != nil {
		return fmt.Errorf("Could not fetch credential %q: %s", machine.Credential, err.Error())
	}
	cred := creds[0] // there is only one, pick up the first one

	var awsCred struct {
		AccessKey string `mapstructure:"access_key"`
		SecretKey string `mapstructure:"secret_key"`
	}

	if err := mapstructure.Decode(cred.Meta, &awsCred); err != nil {
		return err
	}

	if structs.HasZero(awsCred) {
		return fmt.Errorf("softlayer data is incomplete: %v", cred.Meta)
	}

	awsRegion, ok := aws.Regions[machine.Meta.Region]
	if !ok {
		return fmt.Errorf("Malformed region detected: %s", machine.Meta.Region)
	}

	amazonClient, err := amazon.NewAmazonCreds(
		structs.Map(machine.Meta),
		awsRegion.Name,
		creds.Meta.AccessKey,
		creds.Meta.SecretKey,
		p.Log,
	)
	if err != nil {
		return fmt.Errorf("koding-amazon err: %s", err)
	}

	// attach user specific log
	machine.Log = p.Log.New(machine.Id.Hex())

	sess := &session.Session{
		DB:         p.DB,
		Kite:       p.Kite,
		DNSClient:  p.DNSClient,
		DNSStorage: p.DNSStorage,
		Userdata:   p.Userdata,
		AWSClient:  amazonClient,
		Log:        machine.Log,
	}

	// we use session a lot of in Machine owned methods, so that's why we
	// assign it to a field for easy access
	machine.Session = sess

	// we pass it also to the context, so other packages, such as plans checker
	// can make use of it.
	ctx = session.NewContext(ctx, sess)

	machine.Username = user.Name
	machine.User = user
	machine.cleanFuncs = make([]func(), 0)

	ev, ok := eventer.FromContext(ctx)
	if ok {
		machine.Session.Eventer = ev
	}

	return nil
}
