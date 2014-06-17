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
	"github.com/koding/kite/protocol"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

const (
	TERMINAL_NAME    = "terminal"
	TERMINAL_VERSION = "0.1.5"
)

var (
	log         = logger.New(TERMINAL_NAME)
	mongodbConn *mongodb.MongoDB
	conf        *config.Config
)

type Terminal struct {
	Kite              *kite.Kite
	NewKite           *kitelib.Kite
	Name              string
	Version           string
	Region            string
	Port              int
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

	t.Kite.LoadBalancer = func(correlationName string, username string, deadService string) (resultHostKite string) {
		blog := func(v interface{}) {
			log.Info("terminal loadbalancer for [correlationName: '%s' user: '%s' deadService: '%s'] results in --> %v.", correlationName, username, deadService, v)
		}

		errKite := "(error)"

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
				blog(fmt.Sprintf("no hostnameAlias found, returning (error)"))
				return errKite
			}
		}

		if vm.PinnedToHost != "" {
			terminalPinnedHost := strings.Replace(vm.PinnedToHost, "os", "terminal", 1)
			blog(fmt.Sprintf("returning pinnedHost '%s'", terminalPinnedHost))
			return terminalPinnedHost
		}

		if vm.HostKite == "" {
			blog(fmt.Sprintf("hostkite is empty returning (error)"))
			return errKite
		}

		// maintenance and banned will be handled again in validateVM() function,
		// which will return a permission error.
		if vm.HostKite == "(maintenance)" || vm.HostKite == "(banned)" {
			blog(fmt.Sprintf("hostkite (maintenance) or (banned), returning (error)"))
			return errKite
		}

		terminalHostKite := strings.Replace(vm.HostKite, "os", "terminal", 1)

		blog(fmt.Sprintf("returning terminalHostKite %s", terminalHostKite))
		// finally return our result back
		return terminalHostKite
	}

	// this method is special cased in oskite.go to allow foreign access
	t.registerMethod("webterm.connect", false, webtermConnect)
	t.registerMethod("webterm.getSessions", false, webtermGetSessions)
	t.registerMethod("webterm.killSession", false, webtermKillSession)
	t.registerMethod("webterm.ping", false, webtermPing)

	// register methods for new kite and start it
	t.runNewKite()

	log.Info("Terminal kite started. Go!")
	t.Kite.Run()
}

func (t *Terminal) registerMethod(method string, concurrent bool, callback func(*dnode.Partial, *kite.Channel, *virt.VOS) (interface{}, error)) {
	wrapperMethod := func(args *dnode.Partial, channel *kite.Channel) (methodReturnValue interface{}, methodError error) {
		log.Info("[method: %s]  [user: %s]  [vm: %s]", method, channel.Username, channel.CorrelationName)
		if method == "webterm.connect" {
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

		vos, err := t.getVos(channel.Username, channel.CorrelationName)
		if err != nil {
			return nil, err
		}

		return callback(args, channel, vos)
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
	k, err := kodingkite.New(conf, TERMINAL_NAME, TERMINAL_VERSION)
	if err != nil {
		panic(err)
	}

	t.NewKite = k.Kite

	if t.Port != 0 {
		k.Config.Port = t.Port
	} else if k.TLSConfig != nil {
		k.Config.Port = 444
	} else {
		k.Config.Port = 5001
	}

	k.Config.Region = t.Region

	k.SetupSignalHandler()

	t.vosMethod(k, "webterm.getSessions", webtermGetSessionsNew)
	t.vosMethod(k, "webterm.connect", webtermConnectNew)
	t.vosMethod(k, "webterm.killSession", webtermKillSessionNew)
	t.vosMethod(k, "webterm.ping", webtermPingNew)

	k.HandleFunc("kite.who", t.kiteWho)

	k.Config.DisableConcurrency = true // to process incoming messages in order

	go k.Run()
	<-k.Kite.ServerReadyNotify()

	// TODO: remove this later, this is needed in order to reinitiliaze the logger package
	log.SetLevel(t.LogLevel)
}

func (t *Terminal) kiteWho(r *kitelib.Request) (interface{}, error) {
	var params struct {
		VmName string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.VmName == "" {
		return nil, &kite.ArgumentError{Expected: "[string]"}
	}

	var vm *virt.VM
	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostnameAlias": params.VmName}).One(&vm)
	}); err != nil {
		log.Error("kite.who err: %v", err)
		return nil, errors.New("not found")
	}

	hostKite := vm.HostKite
	if vm.HostKite == "" {
		return nil, errors.New("hostkite is empty returning (error)")
	}

	if vm.HostKite == "(maintenance)" {
		return nil, errors.New("hostkite is under maintenance")
	}

	if vm.HostKite == "(banned)" {
		return nil, errors.New("hostkite is marked as (banned)")
	}

	if vm.PinnedToHost != "" {
		hostKite = vm.PinnedToHost

	}

	// hostKite is in form: "kite-os-sj|kontainer1_sj_koding_com"
	s := strings.Split(hostKite, "|")
	if len(s) < 2 {
		return nil, fmt.Errorf("hostkite '%s' is malformed", hostKite)
	}

	// s[1] -> kontainer1_sj_koding_com
	hostname := strings.Replace(s[1], "_", ".", -1)

	proc := t.NewKite.Kite()
	query := protocol.KontrolQuery{
		Username:    proc.Username,
		Environment: proc.Environment,
		Name:        proc.Name,
		Version:     proc.Version,
		Region:      proc.Region,
		Hostname:    hostname,
	}

	return &protocol.WhoResult{
		Query: query,
	}, nil
}

// vosFunc is used to associate each request with a VOS instance.
type vosFunc func(*kitelib.Request, *virt.VOS) (interface{}, error)

// vosMethod is compat wrapper around the new kite library. It's basically
// creates a vos instance that is the plugged into the the base functions.
func (t *Terminal) vosMethod(k *kodingkite.KodingKite, method string, vosFn vosFunc) {
	handler := func(r *kitelib.Request) (interface{}, error) {
		var params struct {
			VmName string
		}

		if r.Args.One().Unmarshal(&params) != nil || params.VmName == "" {
			return nil, errors.New("{ vmName: [string]}")
		}

		if method == "webterm.connect" {
			user, err := getUser(r.Username)
			if err != nil {
				return nil, err
			}

			vm, err := getVM(params.VmName)
			if err != nil {
				return nil, err
			}

			return vosFn(r, &virt.VOS{VM: vm, User: user})
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
