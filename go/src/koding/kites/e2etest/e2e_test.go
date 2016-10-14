package e2etest

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"math/rand"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"koding/kites/kloud/pkg/dnsclient"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

var Test Config

type Config struct {
	// Environment configuration.
	TopDir     string
	Debug      bool
	NoClean    bool
	NoPublic   bool
	NgrokDebug bool // ngrok prints so intensively its debug is enabled separately
	DockerHost string
	Username   string

	// Ngrok configuration.
	NgrokToken string

	// Kontrol configuration.
	KontrolPublic  string
	KontrolPrivate string
	Kontrol        config.Config
	Postgres       kontrol.PostgresConfig

	// EC2/Route53 configuration
	HostedZone string
	AccessKey  string `required:"true"`
	SecretKey  string `required:"true"`

	Log logging.Logger

	// Cleanup resources after tests.
	CleanRoute53 []string

	pemPrivate string
	pemPublic  string
}

func (cfg *Config) String() string {
	p, err := json.MarshalIndent(cfg, "", "\t")
	if err != nil {
		panic(err)
	}
	return string(p)
}

func (cfg *Config) GenKiteConfig() (*config.Config, *url.URL) {
	c := cfg.Kontrol.Copy()
	c.Port = int(50000 + rand.Int31n(10000))
	u := &url.URL{
		Scheme: "http",
		Host:   "127.0.0.1:" + strconv.Itoa(c.Port),
		Path:   "/kite",
	}
	return c, u
}

func TestMain(m *testing.M) {
	rand.Seed(time.Now().UnixNano() + int64(os.Getpid()))
	argsTesting, argsConfig := splitArgs()
	flag.CommandLine.Parse(argsTesting)

	l := multiconfig.MultiLoader(
		&multiconfig.EnvironmentLoader{
			Prefix: "e2etest",
		},
		&multiconfig.FlagLoader{
			EnvPrefix: "e2etest",
			Args:      argsConfig,
		},
	)

	if err := l.Load(&Test); err != nil {
		die("unable to load configuration", err)
	}

	Test.Log = logging.NewCustom("test", Test.Debug)
	Test.setDefaults()

	if Test.Debug {
		fmt.Printf("e2etest.Test = %s\n", &Test)
	}

	ktrl := NewKontrol()
	ktrl.Start()

	exit := m.Run()

	if !Test.NoClean {
		Test.cleanupRoute53()
	}

	ktrl.Close()

	os.Exit(exit)
}

func die(v ...interface{}) {
	fmt.Fprintln(os.Stderr, v...)
	os.Exit(2) // distinct exit code, m.Run exists with 1 on failure
}

func (cfg *Config) setDefaults() {
	if cfg.TopDir == "" {
		p, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
		if err != nil {
			cfg.Log.Warning("unable to get git top dir:", err)
		} else {
			cfg.TopDir = string(bytes.TrimSpace(p))
		}
	}

	if cfg.DockerHost == "" {
		if u, err := url.Parse(os.Getenv("DOCKER_HOST")); err == nil {
			if host, _, err := net.SplitHostPort(u.Host); err == nil {
				cfg.DockerHost = host
			} else {
				cfg.DockerHost = u.Host
			}
		}
	}

	if cfg.Username == "" {
		u, err := user.Current()
		if err == nil {
			cfg.Username = u.Username
		}
	}

	if cfg.KontrolPrivate == "" {
		cfg.KontrolPrivate = filepath.Join(cfg.TopDir, "certs", "test_kontrol_rsa_private.pem")
		p, err := ioutil.ReadFile(cfg.KontrolPrivate)
		if err == nil {
			cfg.pemPrivate = string(p)
		}
	}

	if cfg.KontrolPublic == "" {
		cfg.KontrolPublic = filepath.Join(cfg.TopDir, "certs", "test_kontrol_rsa_public.pem")
		p, err := ioutil.ReadFile(cfg.KontrolPublic)
		if err == nil {
			cfg.pemPublic = string(p)
		}
	}

	if cfg.pemPrivate == "" {
		cfg.pemPrivate = testkeys.Private
	}

	if cfg.pemPublic == "" {
		cfg.pemPublic = testkeys.Public
	}

	if cfg.Kontrol.KontrolURL == "" {
		cfg.Kontrol = config.Config{
			Port:        4000,
			Username:    "koding",
			Environment: "dev",
			Region:      "dev",
			KontrolUser: "koding",
			KontrolKey:  cfg.pemPublic,
			KiteKey:     testutil.NewKiteKeyWithKeyPair(cfg.pemPrivate, cfg.pemPublic).Raw,
			KontrolURL:  "http://localhost:4000/kite",
		}
	}

	if cfg.Postgres == (kontrol.PostgresConfig{}) {
		cfg.Postgres = kontrol.PostgresConfig{
			Host:           cfg.DockerHost,
			Port:           5432,
			Username:       "kontrolapp_2016_05",
			Password:       "kontrolapp_2016_05",
			DBName:         "social",
			ConnectTimeout: 20,
		}
	}

	if cfg.HostedZone == "" {
		cfg.HostedZone = "dev.koding.io"
	}
}

func (c *Config) creds() *credentials.Credentials {
	return credentials.NewStaticCredentials(c.AccessKey, c.SecretKey, "")
}

func (c *Config) NewServer(h http.Handler) *httptest.Server {
	ts := httptest.NewUnstartedServer(h)

	if c.Debug {
		ts.Listener = debugListener{ts.Listener}
	}

	ts.Start()
	return ts
}

func (c *Config) cleanupRoute53() {
	if len(c.CleanRoute53) == 0 {
		c.Log.Info("no Route53 domains to clean")
		return
	}

	dnsOpts := &dnsclient.Options{
		Creds:      c.creds(),
		HostedZone: c.HostedZone,
		Log:        c.Log,
	}
	dns, err := dnsclient.NewRoute53Client(dnsOpts)
	if err != nil {
		c.Log.Warning("failed to clean Route53 domains: %s", err)
		return
	}

	records, err := dns.GetAll("")
	if err != nil {
		c.Log.Warning("failed to get Route53 domains: %s", err)
		return
	}

	for _, suffix := range c.CleanRoute53 {
		for _, rec := range records {
			if strings.HasSuffix(rec.Name, suffix) {
				err := dns.DeleteRecord(rec)
				if err != nil {
					c.Log.Warning("failed to delete record %q: %s", rec.Name, err)
					continue
				}
				c.Log.Info("deleted %q record", rec.Name)
			}
		}
	}
}

func splitArgs() (testing, config []string) {
	args := os.Args[1:]
	for i, arg := range args {
		if arg == "--" {
			return args[:i], args[i+1:]
		}
	}
	return args, []string{}
}

type debugListener struct {
	net.Listener
}

type debugConn struct {
	net.Conn
}

func (dl debugListener) Accept() (net.Conn, error) {
	conn, err := dl.Listener.Accept()
	if err != nil {
		return nil, err
	}
	return debugConn{conn}, nil
}

func (dc debugConn) Write(p []byte) (int, error) {
	fmt.Println("debugConn.Write:")
	return io.MultiWriter(dc.Conn, os.Stderr).Write(p)
}

func (dc debugConn) Read(p []byte) (int, error) {
	fmt.Println("debugConn.Read")
	return io.TeeReader(dc.Conn, os.Stderr).Read(p)
}

func host(s string) string {
	u, err := url.Parse(s)
	if err != nil {
		panic(err)
	}
	return u.Host
}

func port(s string) string {
	_, port, err := net.SplitHostPort(s)
	if err != nil {
		panic(err)
	}
	return port
}
