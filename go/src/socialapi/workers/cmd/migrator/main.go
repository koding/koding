package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/migrator/controller"
	"socialapi/workers/realtime/models"

	"github.com/koding/runner"
)

var (
	Name         = "Migrator"
	flagSchedule = flag.Bool("s", false, "Schedule worker")
	flagPubNub   = flag.Bool("p", false, "Grant public access to channels")
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	pubnub := models.NewPubNub(appConfig.GateKeeper.Pubnub, r.Log)
	defer pubnub.Close()

	handler, err := controller.New(r.Log, pubnub)
	if err != nil {
		panic(err)
	}

	if *flagSchedule {
		r.ShutdownHandler = handler.Shutdown
		if err := handler.Schedule(); err != nil {
			panic(err)
		}
		r.Wait()

		return
	}

	if *flagPubNub {
		handler.GrantPublicAccess()

		return
	}

	handler.Start()
}
