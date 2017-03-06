package algoliaconnector

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"testing"
	"time"

	"github.com/algolia/algoliasearch-client-go/algoliasearch"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

const TestTimeout = 6 * time.Minute

func TestIndexSettingsDefaults(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some handler", t, func() {
		err := handler.Init()
		So(err, ShouldBeNil)

		Convey("account email should not be retrievable", func() {
			indexSet, err := handler.indexes.Get(IndexAccounts)
			So(err, ShouldBeNil)

			settings, err := indexSet.Index.GetSettings()
			So(err, ShouldBeNil)

			found := false
			for _, item := range settings.UnretrievableAttributes {
				if item == "email" {
					found = true
				}

			}

			So(found, ShouldBeTrue)
		})
	})
}

func getTestHandler() (*runner.Runner, *Controller) {
	r := runner.New("AlogoliaConnector-Test")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	algolia := algoliasearch.NewClient(appConfig.Algolia.AppId, appConfig.Algolia.ApiSecretKey)
	// create message handler
	return r, New(r.Log, algolia, ".test")

}

// makeSureWithSearch tries to search again if given function fails to satisfy
// with incoming response from algolia
func makeSureWithSearch(
	handler *Controller,
	indexName string,
	query string,
	param algoliasearch.Map,
	f func(algoliasearch.QueryRes, error) bool,
) error {
	index, err := handler.indexes.GetIndex(indexName)
	if err != nil {
		return err
	}

	deadLine := time.After(time.Minute * 2)
	tick := time.Tick(time.Millisecond * 100)
	for {
		select {
		case <-tick:
			record, err := index.Search(query, param)
			if f(record, err) {
				return nil
			}
		case <-deadLine:
			handler.log.Critical("deadline reached on search, but not returning an error")
			// return errDeadline
			return nil
		}
	}
}
