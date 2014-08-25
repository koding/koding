package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/migrator/controller"
)

var (
	Name         = "Migrator"
	flagSchedule = flag.Bool("s", false, "Schedule worker")
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)

	handler, err := controller.New(r.Log)
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

	handler.Start()
}
