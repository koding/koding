package runner

import (
	"errors"
	"flag"
	"fmt"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
	"net/url"
	"os"
	"os/signal"
	"socialapi/config"
	"socialapi/workers/helper"
	"strconv"
	"syscall"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
)

var (
	flagConfFile = flag.String("c", "", "Configuration profile from file")
	flagRegion   = flag.String("r", "", "Region name")
	flagDebug    = flag.Bool("d", false, "Debug mode")
	flagVersion  = flag.Int("v", 0, "Worker Version")
	flagMetrics  = flag.Bool("m", false, "Output metrics")

	flagKiteInit       = flag.Bool("kite-init", false, "Init kite system with the worker.")
	flagKiteLocal      = flag.Bool("kite-local", false, "Start kite system in local mode.")
	flagKiteProxy      = flag.Bool("kite-proxy", false, "Start kite system behind a proxy")
	flagKiteKontrolURL = flag.String("kite-kontrol-url", "", "Change kite's register URL to kontrol")
)

type Runner struct {
	Log             logging.Logger
	Conf            *config.Config
	Bongo           *bongo.Bongo
	Listener        *worker.Listener
	Name            string
	ShutdownHandler func()
	Done            chan error
	Kite            *kite.Kite
}

func New(name string) *Runner {
	return &Runner{Name: name}
}

func WrapWithVersion(name string, version *int) string {
	return fmt.Sprintf("%s:%d", name, *version)
}

func (r *Runner) Init() error {
	flag.Parse()
	if *flagConfFile == "" {
		return fmt.Errorf("Please define config file with -c Exiting...")
	}

	return r.InitWithConfigFile(*flagConfFile)
}

// InitWithConfigFile used for externally setting config file.
// This is used for testing purposes, and usage of Init method is encouraged
func (r *Runner) InitWithConfigFile(flagConfFile string) error {
	r.Conf = config.MustRead(flagConfFile)
	r.Conf.FlagDebugMode = *flagDebug

	// create logger for our package
	r.Log = helper.CreateLogger(
		WrapWithVersion(r.Name, flagVersion),
		*flagDebug,
	)

	// panics if not successful
	r.Bongo = helper.MustInitBongo(
		WrapWithVersion(r.Name, flagVersion),
		WrapWithVersion(r.Conf.EventExchangeName, flagVersion),
		r.Conf,
		r.Log,
		*flagDebug,
	)

	r.ShutdownHandler = func() {}
	r.Done = make(chan error, 1)
	r.RegisterSignalHandler()

	if *flagKiteInit {
		if err := r.initKite(); err != nil {
			return err
		}
	}

	return nil
}

func (r *Runner) initKite() error {
	// init kite here
	k := kite.New(r.Name, "0.0."+strconv.Itoa(*flagVersion))

	// TODO use get
	k.Config = kiteconfig.MustGet()
	// no need to set, will be set randomly.
	// k.Config.Port = 9876
	k.Config.Environment = r.Conf.Environment
	region := *flagRegion
	// if region is not given, get it from config
	if region == "" {
		region = k.Config.Region
	}

	k.Config.Region = region
	// set kite
	r.Kite = k

	return r.RegisterToKontrol()
}

func (r *Runner) RegisterToKontrol() error {
	if r.Kite == nil {
		return errors.New("kite is not initialized yet")
	}

	registerURL := r.Kite.RegisterURL(*flagKiteLocal)
	if *flagKiteKontrolURL != "" {
		u, err := url.Parse(*flagKiteKontrolURL)
		if err != nil {
			r.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	r.Log.Info("Going to register to kontrol with URL: %s", registerURL)
	if *flagKiteProxy {
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

func (r *Runner) Listen(handler worker.Handler) {
	r.Listener = worker.NewListener(
		WrapWithVersion(r.Name, flagVersion),
		WrapWithVersion(r.Conf.EventExchangeName, flagVersion),
		r.Log,
		*flagMetrics,
	)

	// blocking
	// listen for events
	r.Listener.Listen(helper.NewRabbitMQ(r.Conf, r.Log), handler)
}

func (r *Runner) Close() {
	r.ShutdownHandler()
	if r.Listener != nil {
		r.Listener.Close()
	}
	r.Bongo.Close()
	if *flagKiteInit {
		if r.Kite == nil {
			return
		}

		r.Kite.Close()
	}
}

func (r *Runner) RegisterSignalHandler() {
	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
				r.Close()
				r.Done <- nil
			}
		}
	}()
}

func (r *Runner) Wait() error {
	err := <-r.Done

	return err
}
