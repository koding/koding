package terminal

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/logger"
	"koding/virt"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	TERMINAL_NAME     = "terminal"
	TERMINAL_VERSION  = "0.0.1"
	sessionPrefix     = "koding"
	kodingScreenPath  = "/opt/koding/bin/screen"
	kodingScreenrc    = "/opt/koding/etc/screenrc"
	defaultScreenPath = "/usr/bin/screen"
)

var (
	log               = logger.New(TERMINAL_NAME)
	mongodbConn       *mongodb.MongoDB
	conf              *config.Config
	ErrInvalidSession = "ErrInvalidSession"
)

type Terminal struct {
	Kite     *kite.Kite
	Name     string
	Version  string
	Region   string
	LogLevel logger.Level
}

func New(c *config.Config) *Terminal {
	return &Terminal{}

	conf = c
	mongodbConn = mongodb.NewMongoDB(c.Mongo)
	modelhelper.Initialize(c.Mongo)

	return &Terminal{
		Name:    TERMINAL_NAME,
		Version: TERMINAL_VERSION,
	}
}

func (t *Terminal) Run() {
	if t.Region == "" {
		panic("region is not set for Oskite")
	}

	log.Info("Kite.go preperation started")
	kiteName := "terminal"
	if t.Region != "" {
		kiteName += "-" + t.Region
	}

	t.Kite = kite.New(kiteName, conf, true)

	// this method is special cased in oskite.go to allow foreign access
	t.registerMethod("webterm.connect", false, webtermConnect)
	t.registerMethod("webterm.getSessions", false, webtermGetSessions)

	t.Kite.Run()
}

func (t *Terminal) registerMethod(method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {
	wrapperMethod := func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {
		log.Info("[method: %s]  [user: %s]  [vm: %s]", method, channel.Username, channel.CorrelationName)
		user, err := getUser(channel.Username)
		if err != nil {
			return nil, err
		}

		vm, err := getVM(channel.CorrelationName)
		if err != nil {
			return nil, err
		}

		return callback(args, channel, &virt.VOS{VM: vm, User: user})
	}

	t.Kite.Handle(method, concurrent, wrapperMethod)
}

func getUser(username string) (*virt.User, error) {
	var user *virt.User
	if err := mongodbConn.Run("jUsers", func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).One(&user)
	}); err != nil {
		if err != mgo.ErrNotFound {
			return nil, fmt.Errorf("username lookup error: %v", err)
		}

		if !strings.HasPrefix(username, "guest-") {
			log.Warning("User not found: %v", username)
		}

		time.Sleep(time.Second) // to avoid rapid cycle channel loop
		return nil, &kite.WrongChannelError{}
	}

	if user.Uid < virt.UserIdOffset {
		return nil, errors.New("User with too low uid.")
	}

	return user, nil
}

// getVM returns a new virt.VM struct based on on the given correlationName.
// Here correlationName can be either the hostnameAlias or the given VM
// documents ID.
func getVM(correlationName string) (*virt.VM, error) {
	var vm *virt.VM
	query := bson.M{"hostnameAlias": correlationName}
	if bson.IsObjectIdHex(correlationName) {
		query = bson.M{"_id": bson.ObjectIdHex(correlationName)}
	}

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Find(query).One(&vm)
	}); err != nil {
		return nil, &VMNotFoundError{Name: correlationName}
	}

	vm.ApplyDefaults()
	return vm, nil
}

type VMNotFoundError struct {
	Name string
}

func (err *VMNotFoundError) Error() string {
	return "There is no VM with hostname/id '" + err.Name + "'."
}
