package algoliaconnector

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
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

			settingsinter, err := indexSet.Index.GetSettings()
			So(err, ShouldBeNil)

			settings, ok := settingsinter.(map[string]interface{})[UnretrievableAttributes]
			So(ok, ShouldBeTrue)

			found := false
			for _, item := range settings.([]interface{}) {
				if item.(string) == "email" {
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

// makeSureSynonyms checks if the given index's synonyms request returns the
// desired err, it will re-try every 100ms until deadline of 15 seconds reached.
// Algolia doesnt index the records right away, so try to go to a desired state
// func makeSureSynonyms(handler *Controller, indexName string, f func([][]string, error) bool) error {
// 	deadLine := time.After(TestTimeout)
// 	tick := time.Tick(time.Millisecond * 100)
// 	for {
// 		select {
// 		case <-tick:
// 			synonyms, err := handler.getSynonyms(indexName)
// 			if err != nil {
// 				return err
// 			}
//
// 			if f(synonyms, err) {
// 				return nil
// 			}
// 		case <-deadLine:
// 			handler.log.Critical("deadline reached on making sure sysnonyms but not returning an error")
// 			// return errDeadline
// 			return nil
// 		}
// 	}
// }

func createChannelMessageList(channelId, messageId int64) *models.ChannelMessageList {
	cml := models.NewChannelMessageList()

	cml.ChannelId = channelId
	cml.MessageId = messageId

	So(cml.Create(), ShouldBeNil)

	return cml
}
