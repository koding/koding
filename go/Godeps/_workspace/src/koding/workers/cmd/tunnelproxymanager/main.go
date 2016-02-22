package main

import (
	"fmt"
	"koding/common"
	"koding/workers/tunnelproxymanager"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/koding/logging"
)

const Name = "tunnelproxymanager"

func main() {
	conf, session, err := tunnelproxymanager.Configure()
	if err != nil {
		log.Fatal("Reading config failed: ", err.Error())
	}

	// system name defines all resource names
	systemName := fmt.Sprintf("%s-%s", "tunnelproxymanager", conf.EBEnvName)

	log := common.CreateLogger(Name, conf.Debug)
	// remove formatting from call stack and output correct line
	log.SetCallDepth(1)

	// create record manager
	recordManager := tunnelproxymanager.NewRecordManager(session, log, conf.Region, conf.HostedZone)
	if err := recordManager.Init(); err != nil {
		log.Fatal(err.Error())
	}

	// create lifecycle
	l := tunnelproxymanager.NewLifeCycle(session, log, conf.AutoScalingName)

	// configure lifecycle with system name
	if err := l.Configure(systemName); err != nil {
		log.Fatal(err.Error())
	}

	done := registerSignalHandler(l, log)

	// listen to lifecycle events
	if err := l.Listen(recordManager); err != nil {
		log.Fatal(err.Error())
	}

	<-done
}

func registerSignalHandler(l *tunnelproxymanager.LifeCycle, log logging.Logger) chan struct{} {
	done := make(chan struct{}, 1)

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)

		signal := <-signals
		switch signal {
		case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
			log.Info("recieved exit signal, closing...")
			err := l.Close()
			if err != nil {
				log.Critical(err.Error())
			}
			close(done)
		}

	}()
	return done
}
