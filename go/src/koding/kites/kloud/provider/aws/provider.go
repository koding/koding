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

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/fatih/structs"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/mitchellh/mapstructure"
	"golang.org/x/net/context"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
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
	err := p.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.FindId(bson.ObjectIdHex(id)).One(&machine.Machine)
	})
	if err == mgo.ErrNotFound {
		return nil, kloud.NewError(kloud.ErrMachineNotFound)
	}
	if err != nil {
		return nil, err
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not available")
	}

	meta, err := machine.GetMeta()
	if err != nil {
		return nil, err
	}

	if meta.Region == "" {
		return nil, errors.New("region is not set")
	}

	p.Log.Debug("Using region: %s", meta.Region)

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

	meta, err := machine.GetMeta()
	if err != nil {
		return err
	}

	creds, err := modelhelper.GetCredentialDatasFromIdentifiers(machine.Credential)
	if err != nil {
		return fmt.Errorf("Could not fetch credential %q: %s", machine.Credential, err)
	}

	if len(creds) == 0 {
		return fmt.Errorf("aws no credential data available for credential: %s", machine.Credential)
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
		return fmt.Errorf("aws data is incomplete: %v", cred.Meta)
	}

	opts := &amazon.ClientOptions{
		Credentials: credentials.NewStaticCredentials(awsCred.AccessKey, awsCred.SecretKey, ""),
		Region:      meta.Region,
		Log:         p.Log.New(machine.ObjectId.Hex()),
	}

	amazonClient, err := amazon.NewWithOptions(machine.Meta, opts)
	if err != nil {
		return fmt.Errorf("koding-amazon err: %s", err)
	}

	machine.Log = opts.Log // attach user specific log

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
