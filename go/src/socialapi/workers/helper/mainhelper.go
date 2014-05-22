package helper

import (
	"flag"
	"fmt"
	"socialapi/config"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
)

var (
	flagConfFile = flag.String("c", "", "Configuration profile from file")
	flagDebug    = flag.Bool("d", false, "Debug mode")
	flagVersion  = flag.Int("v", 0, "Worker Version")
)

type Runner struct {
	Log      logging.Logger
	Conf     *config.Config
	Bongo    *bongo.Bongo
	Listener *worker.Listener
	Name     string
}

func (r *Runner) Init(name string) error {
	r.Name = name
	flag.Parse()
	if *flagConfFile == "" {
		return fmt.Errorf("Please define config file with -c Exiting...")
	}

	r.Conf = config.MustRead(*flagConfFile)

	// create logger for our package
	r.Log = CreateLogger(
		WrapWithVersion(r.Name, flagVersion),
		*flagDebug,
	)

	// panics if not successful
	r.Bongo = MustInitBongo(
		WrapWithVersion(r.Name, flagVersion),
		WrapWithVersion(r.Conf.EventExchangeName, flagVersion),
		r.Conf,
		r.Log,
	)

	return nil
}

func (r *Runner) Listen(handler worker.Handler) {
	listener := worker.NewListener(
		WrapWithVersion(r.Name, flagVersion),
		WrapWithVersion(r.Conf.EventExchangeName, flagVersion),
		r.Log,
	)

	// blocking
	// listen for events
	listener.Listen(NewRabbitMQ(r.Conf, r.Log), handler)
}

func (r *Runner) Close() {
	r.Listener.Close()
	r.Bongo.Close()
}
