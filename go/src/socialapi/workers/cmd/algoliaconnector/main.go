package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"

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
		fmt.Println(err)
		return
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
	r.Register(models.Channel{}).OnCreate().Handle((*algoliaconnector.Controller).ChannelCreated)
	r.Register(models.Channel{}).OnUpdate().Handle((*algoliaconnector.Controller).ChannelUpdated)
	r.Register(models.Account{}).OnCreate().Handle((*algoliaconnector.Controller).AccountCreated)
	r.Register(models.Account{}).OnUpdate().Handle((*algoliaconnector.Controller).AccountUpdated)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*algoliaconnector.Controller).MessageListSaved)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*algoliaconnector.Controller).MessageListDeleted)
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*algoliaconnector.Controller).MessageUpdated)

	// moderation related
	r.Register(models.ChannelLink{}).OnCreate().Handle((*algoliaconnector.Controller).ChannelLinkCreated)

	// participant related events
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*algoliaconnector.Controller).ParticipantCreated)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*algoliaconnector.Controller).ParticipantUpdated)

	r.Listen()
	r.Wait()
}
