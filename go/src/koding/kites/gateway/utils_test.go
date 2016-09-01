package gateway_test

import (
	"fmt"
	"os"
	"time"

	"koding/kites/gateway"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kitetest"
	"github.com/koding/multiconfig"
)

// DefaultKeyPair is a pem-encoded rsa private/public
// key pair, used to generate kite.key values.
var DefaultKeyPair = must(kitetest.GenerateKeyPair())

// Driver is a test driver that provides mocking / spying
// functionality for control types of gateway package.
type Driver struct {
	KeyPair *kitetest.KeyPair // key pair to use for generating kite.keys; DefaultKeyPair by default
	ChanCap int               // buffer size of spying channels
}

// AuthFunc spies on cfg.AuthFunc calls, sending passed AuthRequest
// to the returned channel.
//
// If cfg.AuthFunc is non-nil, it is called after the value is sent.
func (d *Driver) AuthFunc(cfg *gateway.Config) <-chan *gateway.AuthRequest {
	ch := make(chan *gateway.AuthRequest, d.ChanCap)
	fn := cfg.AuthFunc

	cfg.AuthFunc = func(req *gateway.AuthRequest) error {
		ch <- req

		if fn != nil {
			return fn(req)
		}

		return nil
	}

	return ch
}

// BeforeFunc spies on cfg.BeforeFunc calls, sending passed time.Time
// to the returned channel.
//
// If cfg.BeforeFunc is non-nil, it is called after the value is sent.
func (d *Driver) BeforeFunc(cfg *gateway.Config) <-chan time.Time {
	ch := make(chan time.Time, d.ChanCap)
	fn := cfg.BeforeFunc

	cfg.BeforeFunc = func(t time.Time) bool {
		ch <- t

		if fn != nil {
			return fn(t)
		}

		return gateway.Before(t)
	}

	return ch
}

// Kite sets cfg.Kite with kite.key generated for the given username.
func (d *Driver) Kite(cfg *gateway.Config, username string) *gateway.Config {
	key, err := kitetest.GenerateKiteKey(&kitetest.KiteKey{Username: username}, d.keyPair())
	if err != nil {
		panic(err)
	}

	cfgCopy := *cfg
	cfgCopy.Kite = kite.New(username, "0.0.1")
	cfgCopy.Kite.Config = &config.Config{
		Username:    username,
		Environment: "test",
		Region:      "test",
		KontrolKey:  string(d.keyPair().Public),
		KiteKey:     key.Raw,
	}

	return &cfgCopy
}

// Server starts gateway server created from the given configuration.
//
// It returns a function that can be used to explicitely stop
// the kite server.
func (d *Driver) Server(cfg *gateway.Config) (cancel func()) {
	kiteCfg := d.Kite(cfg, "gateway")

	gateway.NewServer(kiteCfg)

	go kiteCfg.Kite.Run()
	<-kiteCfg.Kite.ServerReadyNotify()

	cfg.ServerURL = fmt.Sprintf("http://127.0.0.1:%d/kite", kiteCfg.Kite.Port())

	return kiteCfg.Kite.Close
}

func (d *Driver) keyPair() *kitetest.KeyPair {
	if d.KeyPair != nil {
		return d.KeyPair
	}

	return DefaultKeyPair
}

// ParseFlags uses multiconfig to fill the given v with matching
// flag values read from tags, environment and command line.
func ParseFlags(v interface{}) error {
	args := make([]string, 0) // non-nil to force FlagLoader to not read test flags

	for i, arg := range os.Args {
		if arg == "--" {
			args = os.Args[i+1:]
			break
		}
	}

	mc := multiconfig.New()
	mc.Loader = multiconfig.MultiLoader(
		&multiconfig.TagLoader{},
		&multiconfig.EnvironmentLoader{
			Prefix: "GATEWAY",
		},
		&multiconfig.FlagLoader{
			Args: args,
		},
	)

	return mc.Load(v)
}

func must(kp *kitetest.KeyPair, err error) *kitetest.KeyPair {
	if err != nil {
		panic(err)
	}

	return kp
}
