package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/team"

	"github.com/koding/runner"
)

var (
	// Name holds the worker name
	Name = "Participant Cleaner"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// get participants
	cps := fetchPartcipantsWithNick()

	// init controller
	controller := team.NewController(r.Log, appConfig)

	// TODO
	// iterate over participants and remove each of participant
	for _, cp := range cps {
		_ = controller.HandleParticipant(cp)
	}

}

func fetchPartcipantsWithNick() []*models.ChannelParticipant {
	return nil
}
