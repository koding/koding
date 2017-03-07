package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/models"

	"github.com/koding/runner"
)

var (
	Name = "AccountRemover"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	go r.Wait()

	if err := models.DeleteDiffedDBAccounts(); err != nil {
		fmt.Println("error while deleting account that non-existing in mongo", err)
		return
	}

}
