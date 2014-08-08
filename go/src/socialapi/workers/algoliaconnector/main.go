package main

import (
	"fmt"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"

	"socialapi/models"
	"socialapi/workers/algoliaconnector/algoliaconnector"
	"socialapi/workers/common/runner"
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

	algolia := algoliasearch.NewClient(r.Conf.Algolia.AppId, r.Conf.Algolia.ApiKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, r.Conf.Algolia.IndexSuffix)
	r.SetContext(handler)
	r.Register(models.Channel{}).OnCreate().Handle((*algoliaconnector.Controller).TopicSaved)
	r.Listen()
	r.Wait()
}
