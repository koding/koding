package keygentest

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"koding/kites/keygen"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kitetest"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

// Flags represents command line flags used for configuring gateway-related
// e2e tests.
//
// In order to set or override the value, set the flags after
// the -- separator, e.g.:
//
//   $ go test koding/kites/gateway -- -accesskey abc -secretkey def
//
type Flags struct {
	EnvPrefix string        `default:"keygen"`
	AccessKey string        `required:"true"`
	SecretKey string        `required:"true"`
	Bucket    string        `default:"kodingdev-publiclogs"`
	Region    string        `default:"us-east-1"`
	Expire    time.Duration `default:"15m0s"`
}

// Config creates new gateway.Config value from the given flags.
func (f *Flags) Config() *keygen.Config {
	return &keygen.Config{
		AccessKey:  f.AccessKey,
		SecretKey:  f.SecretKey,
		Bucket:     f.Bucket,
		AuthExpire: f.Expire,
		Region:     f.Region,
		Log:        logging.NewCustom("gateway-test", testing.Verbose()),
	}
}

// AWSConfig creates new aws.Config value from the given flags.
func (f *Flags) AWSConfig() *aws.Config {
	return &aws.Config{
		Credentials: credentials.NewStaticCredentials(f.AccessKey, f.SecretKey, ""),
		Region:      &f.Region,
	}
}

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
func (d *Driver) AuthFunc(cfg *keygen.Config) <-chan *keygen.AuthRequest {
	ch := make(chan *keygen.AuthRequest, d.ChanCap)
	fn := cfg.AuthFunc

	cfg.AuthFunc = func(req *keygen.AuthRequest) error {
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
func (d *Driver) BeforeFunc(cfg *keygen.Config) <-chan time.Time {
	ch := make(chan time.Time, d.ChanCap)
	fn := cfg.BeforeFunc

	cfg.BeforeFunc = func(t time.Time) bool {
		ch <- t

		if fn != nil {
			return fn(t)
		}

		return keygen.DefaultBefore(t)
	}

	return ch
}

// Kite sets cfg.Kite with kite.key generated for the given username.
func (d *Driver) Kite(cfg *keygen.Config, username string) *keygen.Config {
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
// It returns a function that can be used to explicitly stop
// the kite server.
func (d *Driver) Server(cfg *keygen.Config) (cancel func()) {
	kiteCfg := d.Kite(cfg, "keygen")

	keygen.NewServer(kiteCfg)

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
	type parentFlags interface {
		Underlying() *Flags
	}

	envPrefix := "keygen"

	// Try to read the EnvPrefix from the v, so it is possible
	// to set different flags for different tests when
	// run at once e.g. with:
	//
	//   go test ./...
	//
	switch f := v.(type) {
	case *Flags:
		if f.EnvPrefix != "" {
			envPrefix = f.EnvPrefix
		}
	case parentFlags:
		if f := f.Underlying(); f.EnvPrefix != "" {
			envPrefix = f.EnvPrefix
		}
	}

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
			Prefix: strings.ToUpper(envPrefix),
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
