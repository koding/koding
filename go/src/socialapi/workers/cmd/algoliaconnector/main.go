package main

import (
	"koding/db/mongodb/modelhelper"
	"log"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/koding/runner"
)

var (
	Name = "AlgoliaConnector"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err.Error())
	}

	appConfig := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)
	if err := handler.Init(); err != nil {
		//  this is not a blocker for algoliaconnector worker, we can continue working
		r.Log.Error("Err while init: %s", err.Error())
	}

	r.SetContext(handler)
	r.Register(models.Account{}).OnCreate().Handle((*algoliaconnector.Controller).AccountCreated)
	r.Register(models.Account{}).OnUpdate().Handle((*algoliaconnector.Controller).AccountUpdated)

	// participant related events
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*algoliaconnector.Controller).ParticipantCreated)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*algoliaconnector.Controller).ParticipantUpdated)

	r.Listen()
	r.Wait()
}
