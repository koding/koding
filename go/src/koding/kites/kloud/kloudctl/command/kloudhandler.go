package command

import (
	"math/rand"
	"net/http"
	"net/http/cookiejar"
	"os"
	"sync"
	"sync/atomic"
	"time"

	"koding/tools/util"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/sockjsclient"
)

func init() {
	rand.Seed(time.Now().UTC().UnixNano() + int64(os.Getpid()))
}

// KloudArgs is used as argument that is sent to kloud
type KloudArgs struct {
	MachineId  string `json:"machineId"`
	SnapshotId string `json:"snapshotId"`
	Username   string `json:"username"`
	Provider   string `json:"provider"`
}

type Actioner interface {
	Action([]string) error
}

type ActionFunc func(args []string) error

func (a ActionFunc) Action(args []string) error {
	return a(args)
}

func kloudWrapper(args []string, actioner Actioner) error {
	err := actioner.Action(args)
	if err != nil {
		DefaultUi.Error(err.Error())
		return err
	}

	return nil
}

type Client struct {
	jar *cookiejar.Jar
}

func NewClient() *Client {
	jar, err := cookiejar.New(nil)
	if err != nil {
		// Current cookiejar.New implementation always returns nil error,
		// panicing just in case this changed in future.
		panic("internal failure creating cookiejar: " + err.Error())
	}
	return &Client{jar: jar}
}

func (c *Client) Client(opts *sockjsclient.DialOptions) *http.Client {
	return &http.Client{
		Timeout: opts.Timeout,
		Jar:     c.jar,
	}
}

var defaultBK balancedKlients

type balancedKlients struct {
	kite    *kite.Kite
	klouds  []string
	failCnt []int32
	once    util.OnceSuccessful
	mu      sync.Mutex // protects init
}

func (bk *balancedKlients) init() error {
	bk.mu.Lock()
	defer bk.mu.Unlock()

	k := kite.New("kloudctl", "0.0.1")
	c, err := config.Get()
	if err != nil {
		return err
	}

	k.Config = c
	k.Config.KontrolURL = flagKontrolURL
	k.Config.Transport = config.XHRPolling
	if flagDebug {
		k.SetLogLevel(kite.DEBUG)
	} else {
		k.SetLogLevel(kite.WARNING)
	}

	// use production environment by default
	if c.Environment == "" || c.Environment == "unknown" {
		c.Environment = "production"
	}

	query := &protocol.KontrolQuery{
		Name:        "kloud",
		Environment: c.Environment,
	}

	// Try up to three times.
	//
	// TODO(rjeczalik): make the GetKites timeout configurable.
	var klients []*kite.Client
	for i := 0; i < 3; i++ {
		klients, err = k.GetKites(query)
		if err == nil {
			break
		}

		k.Log.Debug("GetKites(%+v) failed: %s", query, err)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		return err
	}

	uniq := make(map[string]struct{})

	// in production environment klouds are balanced behind
	// https://kontrol.com/kloud/kite, however get the uniq URLs
	// in case we're running in different env
	for i, klient := range klients {
		k.Log.Debug("kloud[%d] = %s", i, klient.Kite.Hostname)
		uniq[klient.URL] = struct{}{}
	}

	delete(uniq, "")

	klouds := make([]string, 0, len(uniq))
	for url := range uniq {
		klouds = append(klouds, url)
	}

	bk.kite = k
	bk.klouds = klouds
	bk.failCnt = make([]int32, len(klouds))

	return nil
}

func (bk *balancedKlients) kloudClient() (*kite.Client, error) {
	if err := bk.once.Do(bk.init); err != nil {
		return nil, err
	}

	return bk.kloudClientRetry()
}

func (bk *balancedKlients) kloudClientRetry() (*kite.Client, error) {
	klient, n := bk.newRandKlient()

	err := klient.DialTimeout(time.Second * 15)
	if err != nil {
		if atomic.AddInt32(&bk.failCnt[n], 1) > 5 {
			bk.kite.Log.Error("dial has timed out more than 5 times, reinitializing")
			if e := bk.init(); e != nil {
				return nil, err
			}
		}

		return bk.kloudClientRetry()
	}

	atomic.StoreInt32(&bk.failCnt[n], 0) // zero the fail counter

	return klient, nil
}

func (bk *balancedKlients) newRandKlient() (*kite.Client, int) {
	n := int(rand.Int31n(int32(len(bk.klouds))))
	remoteURL := bk.klouds[n]

	bk.kite.Log.Debug("using %dth kloud: %s", n, remoteURL)

	klient := bk.kite.NewClient(remoteURL)
	klient.Reconnect = true
	klient.ClientFunc = NewClient().Client
	klient.Auth = &kite.Auth{
		Type: "kloudSecret",
		Key:  os.Getenv("KLOUDCTL_SECRETKEY"),
	}

	return klient, n
}

func kloudClient() (*kite.Client, error) {
	return defaultBK.kloudClient()
}
