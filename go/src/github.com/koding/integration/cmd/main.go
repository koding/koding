package main

import (
	"os"
	"os/signal"
	"syscall"

	"github.com/koding/integration"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
	"github.com/rcrowley/go-tigertonic"
)

var (
	done    chan struct{}
	closing bool
)

type Conf struct {
	RootPath string `env:"key=INTEGRATION_WEBHOOK_SERVER"`
	Addr     string `env:"key=INTEGRATION_ADDRESS"`
}

func NewConf() *Conf {
	return &Conf{
		RootPath: "https://koding.com",
		Addr:     "localhost:1234",
	}
}

func main() {
	done = make(chan struct{})
	m := multiconfig.New()
	conf := NewConf()
	m.MustLoad(conf)

	log := logging.NewLogger("webhook")

	h := integration.NewHandler(log, conf.RootPath)
	mux := tigertonic.NewTrieServeMux()
	mux.Handle("POST", "/push", tigertonic.Marshaled(h.Push))
	server := tigertonic.NewServer(conf.Addr, mux)

	go func() {
		go registerSignalHandler()
		<-done
		closing = true
		if err := server.Close(); err != nil {
			log.Error("Could not closed successfully: %s", err)
		}
	}()

	if err := server.ListenAndServe(); err != nil {
		if !closing {
			log.Fatal("Could not initialize server: %s", err)
		}
	}
	log.Info("Server connection is succesfully closed")
}

func registerSignalHandler() {
	signals := make(chan os.Signal, 1)
	signal.Notify(signals)
	for {
		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
			close(done)
		}
	}
}
