package terminal

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kodingkite"
	"koding/tools/config"
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/tools/logger"
	"koding/virt"
	"strings"
	"time"

	kitelib "github.com/koding/kite"
	"github.com/koding/kite/simple"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	TERMINAL_NAME    = "terminal"
	TERMINAL_VERSION = "0.0.2"
)

var (
	log         = logger.New(TERMINAL_NAME)
	mongodbConn *mongodb.MongoDB
	conf        *config.Config
)

type Terminal struct {
	Kite              *kite.Kite
	Name              string
	Version           string
	Region            string
	LogLevel          logger.Level
	ServiceUniquename string
}

func New(c *config.Config) *Terminal {
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

	log.SetLevel(t.LogLevel)
	log.Info("Kite.go preperation started")

	kiteName := "terminal"
	if t.Region != "" {
		kiteName += "-" + t.Region
	}

	t.Kite = kite.New(kiteName, conf, true)

	// Default is "broker", we are going to use another one. In our case its "brokerKite"
	t.Kite.PublishExchange = conf.BrokerKite.Name
	t.ServiceUniquename = t.Kite.ServiceUniqueName

	if t.LogLevel == logger.DEBUG {
		kite.EnableDebug()
	}

	t.Kite.LoadBalancer = func(correlationName string, username string, deadService string) string {
		blog := func(v interface{}) {
			log.Info("terminal loadbalancer for [correlationName: '%s' user: '%s' deadService: '%s'] results in --> %v.", correlationName, username, deadService, v)
		}

		resultOskite := t.ServiceUniquename

		var vm *virt.VM
		if bson.IsObjectIdHex(correlationName) {
			mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
				return c.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
			})
		}

		if vm == nil {
			if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
				return c.Find(bson.M{"hostnameAlias": correlationName}).One(&vm)
			}); err != nil {
				blog(fmt.Sprintf("no hostnameAlias found, returning %s", resultOskite))
				return resultOskite // no vm was found, return this oskite
			}
		}

		if vm.PinnedToHost != "" {
			blog(fmt.Sprintf("returning pinnedHost '%s'", vm.PinnedToHost))
			return vm.PinnedToHost
		}

		if vm.HostKite == "" {
			blog(fmt.Sprintf("hostkite is empty returning '%s'", resultOskite))
			return resultOskite
		}

		// maintenance and banned will be handled again in valideVM() function,
		// which will return a permission error.
		if vm.HostKite == "(maintenance)" || vm.HostKite == "(banned)" {
			blog(fmt.Sprintf("hostkite is %s returning '%s'", vm.HostKite, resultOskite))
			return resultOskite
		}

		// Set hostkite to nil if we detect a dead service. On the next call,
		// Oskite will point to an health service in validateVM function()
		// because it will detect that the hostkite is nil and change it to the
		// healthy service given by the client, which is the returned
		// k.ServiceUniqueName.
		if vm.HostKite == deadService {
			blog(fmt.Sprintf("dead service detected %s returning '%s'", vm.HostKite, t.ServiceUniquename))
			if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
				return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
			}); err != nil {
				log.LogError(err, 0, vm.Id.Hex())
			}

			return resultOskite
		}

		return vm.HostKite
	}

	// this method is special cased in oskite.go to allow foreign access
	t.registerMethod("webterm.connect", false, webtermConnect)
	t.registerMethod("webterm.getSessions", false, webtermGetSessions)
	t.registerMethod("webterm.killSession", false, webtermKillSession)

	// register methods for new kite and start it
	t.runNewKite()

	log.Info("Terminal kite started. Go!")
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

func (t *Terminal) runNewKite() {
	log.Info("Run newkite.")
	k := kodingkite.New(conf, TERMINAL_NAME, TERMINAL_VERSION)
	k.Config.Port = 5001
	k.Config.Region = t.Region

	t.vosMethod(k, "webterm.getSessions", webtermGetSessionsNew)
	t.vosMethod(k, "webterm.connect", webtermGetSessionsNew)
	t.vosMethod(k, "webterm.killSession", webtermGetSessionsNew)
	k.DisableConcurrency() // needed for webterm.connect

	k.Start()

	// TODO: remove this later, this is needed in order to reinitiliaze the logger package
	log.SetLevel(t.LogLevel)
}

// vosFunc is used to associate each request with a VOS instance.
type vosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

// vosMethod is compat wrapper around the new kite library. It's basically
// creates a vos instance that is the plugged into the the base functions.
func (t *Terminal) vosMethod(k *simple.Simple, method string, vosFn vosFunc) {
	handler := func(r *kitelib.Request) (interface{}, error) {
		var params struct {
			VmName string
		}

		if r.Args.One().Unmarshal(&params) != nil || params.VmName == "" {
			return nil, errors.New("{ vmName: [string]}")
		}

		vos, err := t.getVos(r.Username, params.VmName)
		if err != nil {
			return nil, err
		}

		return vosFn(r, vos)
	}

	k.HandleFunc(method, handler)
}

// getVos returns a new VOS based on the given username and vmName
// which is used to pick up the correct VM.
func (t *Terminal) getVos(username, vmName string) (*virt.VOS, error) {
	user, err := getUser(username)
	if err != nil {
		return nil, err
	}

	vm, err := checkAndGetVM(username, vmName)
	if err != nil {
		return nil, err
	}

	permissions := vm.GetPermissions(user)
	if permissions == nil && user.Uid != virt.RootIdOffset {
		return nil, errors.New("Permission denied.")
	}

	return &virt.VOS{
		VM:          vm,
		User:        user,
		Permissions: permissions,
	}, nil
}

// checkAndGetVM returns a new virt.VM struct based on on the given username
// and vm name. If the user doesn't have any associated VM it returns a
// VMNotFoundError.
func checkAndGetVM(username, vmName string) (*virt.VM, error) {
	var vm *virt.VM
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"hostnameAlias": vmName,
			"webHome":       username,
		}).One(&vm)
	}

	if err := mongodbConn.Run("jVMs", query); err != nil {
		return nil, &VMNotFoundError{Name: vmName}
	}

	vm.ApplyDefaults()
	return vm, nil
}
