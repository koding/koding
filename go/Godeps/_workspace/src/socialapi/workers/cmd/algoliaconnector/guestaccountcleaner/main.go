package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/algoliaconnector/algoliaconnector"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/runner"
)

var Name = "AlgoliaGuestCleaner"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)

	// create message handler
	handler := algoliaconnector.New(r.Log, algolia, appConfig.Algolia.IndexSuffix)

	// delete all account that starts with 'guest-'
	if err := handler.DeleteNicksWithQuery("guest-"); err != nil {
		r.Log.Error("Could not delete guest accounts: %s", err)
	}

}
