package main

import (
	"log"
	"socialapi/config"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/runner"
)

// Name is the name for runner
var Name = "AlgoliaAccountCleaner"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)

	if err := handler.DeleteNicksWithQuery(""); err != nil {
		r.Log.Error("Could not remove guest accounts: %s", err)
	}
}
