package runner

import (
	"errors"
	"flag"
	"fmt"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"github.com/koding/metrics"

	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/logging"
)

type flagConfig struct {
	confFile       *string
	region         *string
	debug          *bool
	version        *int
	outputMetrics  *bool
	kiteInit       *bool
	kiteLocal      *bool
	kiteProxy      *bool
	kiteKontrolURL *string
	host           *string
	port           *string
}

type Runner struct {
	Log             logging.Logger
	Conf            *Config
	Bongo           *bongo.Bongo
	Name            string
	ShutdownHandler func()
	Done            chan error
	Kite            *kite.Kite
	Metrics         *metrics.Metrics
	DogStatsD       *metrics.DogStatsD

	flag *flagConfig
}

func New(name string) *Runner {

	f1 := flag.NewFlagSet(name, flag.ExitOnError)

	c := &flagConfig{
		confFile:       f1.String("c", "", "Configuration profile from file"),
		region:         f1.String("r", "", "Region name"),
		debug:          f1.Bool("d", false, "Debug mode"),
		version:        f1.Int("v", 0, "Worker Version"),
		outputMetrics:  f1.Bool("outputMetrics", false, "Output metrics"),
		kiteInit:       f1.Bool("kite-init", false, "Init kite system with the worker."),
		kiteLocal:      f1.Bool("kite-local", false, "Start kite system in local mode."),
		kiteProxy:      f1.Bool("kite-proxy", false, "Start kite system behind a proxy"),
		kiteKontrolURL: f1.String("kite-kontrol-url", "", "Change kite's register URL to kontrol"),
		// for socialAPI worker
		host: f1.String("host", "0.0.0.0", "listen address"),
		port: f1.String("port", "7000", "listen port"),
	}

	if err := f1.Parse(os.Args[1:]); err != nil {
		panic(err.Error())
	}

	return &Runner{Name: name, flag: c}
}

func WrapWithVersion(name string, version *int) string {
	return fmt.Sprintf("%s:%d", name, *version)
}

func (r *Runner) Init() error {
	return r.InitWithConfigFile(*r.flag.confFile)
}

// InitWithConfigFile used for externally setting config file.
// This is used for testing purposes, and usage of Init method is encouraged
func (r *Runner) InitWithConfigFile(configFile string) error {

	// set config file after parsing
	if configFile == "" {
		configFile = *r.flag.confFile
	}

	r.Conf = MustRead(configFile)

	// override Debug if only it is true
	if *r.flag.debug {
		r.Conf.Debug = *r.flag.debug
	}

	r.Conf.Host = *r.flag.host
	r.Conf.Port = *r.flag.port

	// create logger for our package
	r.Log = CreateLogger(
		WrapWithVersion(r.Name, r.flag.version),
		r.Conf.Debug,
	)

	metrics, dogstatsd := CreateMetrics(r.Name, r.Log, *r.flag.outputMetrics)
	r.Metrics = metrics
	r.DogStatsD = dogstatsd

	// panics if not successful
	r.Bongo = MustInitBongo(
		WrapWithVersion(r.Name, r.flag.version),
		WrapWithVersion(r.Conf.EventExchangeName, r.flag.version),
		r.Conf,
		r.Log,
		metrics,
		r.Conf.Debug,
	)

	r.ShutdownHandler = func() {}
	r.Done = make(chan error, 1)
	r.RegisterSignalHandler()

	if *r.flag.kiteInit {
		if err := r.initKite(); err != nil {
			return err
		}

	}

	// set config file path
	r.Conf.Path = configFile

	return nil
}

func (r *Runner) initKite() error {
	// init kite here
	k := kite.New(r.Name, "0.0."+strconv.Itoa(*r.flag.version))

	var err error
	k.Config, err = kiteconfig.Get()
	if err != nil {
		return err
	}

	// no need to set, will be set randomly.
	// k.Config.Port = 9876
	k.Config.Environment = r.Conf.Environment
	region := *r.flag.region
	// if region is not given, get it from config
	if region == "" {
		region = k.Config.Region
	}

	k.Config.Region = region
	// set kite
	r.Kite = k

	return nil
}

// RegisterToKontrol registers the worker to the kontrol, this should be called
// explicitly until further notice :)
func (r *Runner) RegisterToKontrol() error {
	if r.Kite == nil {
		return errors.New("kite is not initialized yet")
	}

	registerURL := r.Kite.RegisterURL(*r.flag.kiteLocal)
	if *r.flag.kiteKontrolURL != "" {
		u, err := url.Parse(*r.flag.kiteKontrolURL)
		if err != nil {
			r.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	r.Log.Info("Going to register to kontrol with URL: %s", registerURL)
	if *r.flag.kiteProxy {
		// Koding proxies in production only
		proxyQuery := &protocol.KontrolQuery{
			Username:    "koding",
			Environment: "production",
			Name:        "proxy",
		}

		r.Log.Info("Seaching proxy: %#v", proxyQuery)
		go r.Kite.RegisterToProxy(registerURL, proxyQuery)
		return nil
	}

	return r.Kite.RegisterForever(registerURL)
}

func (r *Runner) SetContext(controller broker.ErrHandler) {
	r.Bongo.Broker.SetContext(controller)
}

func (r *Runner) ListenFor(eventName string, handleFunc interface{}) error {
	return r.Bongo.Broker.Subscribe(eventName, handleFunc)
}

func (r *Runner) Listen() error {
	// blocking
	// listen for events
	return r.Bongo.Broker.Listen()
}

func (r *Runner) Close() error {
	r.ShutdownHandler()
	err := r.Bongo.Close()
	if *r.flag.kiteInit {
		if r.Kite == nil {
			// dont forget to return the error
			return err
		}

		r.Kite.Close()
	}

	if r.DogStatsD != nil {
		r.DogStatsD.Close()
	}

	return err
}

func (r *Runner) RegisterSignalHandler() {
	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
				err := r.Close()
				r.Done <- err
			}
		}
	}()
}

func (r *Runner) Wait() error {
	err := <-r.Done
	r.Log.Info("Runner closed successfully %t", err == nil)
	return err
}
