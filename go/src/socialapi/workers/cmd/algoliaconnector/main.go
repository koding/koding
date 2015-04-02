package main

import (
	"fmt"

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

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)
	r.SetContext(handler)
	r.Register(models.Channel{}).OnCreate().Handle((*algoliaconnector.Controller).TopicSaved)
	r.Register(models.Account{}).OnCreate().Handle((*algoliaconnector.Controller).AccountSaved)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*algoliaconnector.Controller).MessageListSaved)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*algoliaconnector.Controller).MessageListDeleted)
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*algoliaconnector.Controller).MessageUpdated)

	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*algoliaconnector.Controller).ParticipantCreated)
	r.Register(models.ChannelParticipant{}).OnDelete().Handle((*algoliaconnector.Controller).ParticipantDeleted)

	r.Listen()
	r.Wait()
}
