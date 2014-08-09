package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/migrator/controller"
)

var (
	Name = "Migrator"
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

	if err := handler.Start(); err != nil {
		panic(err)
	}

}
