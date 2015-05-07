package algoliaconnector

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"strings"
	"testing"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAccountSaved(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(err, ShouldBeNil)
		So(acc, ShouldNotBeNil)

		Convey("it should save the document to algolia", func() {
			err := handler.AccountCreated(acc)
			So(err, ShouldBeNil)

			Convey("it should have email in it", func() {
				// make sure account is there
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				record, err := handler.get(IndexAccounts, acc.OldId)
				So(err, ShouldBeNil)
				So(record["email"], ShouldContainSubstring, "@koding.com")
			})

		})
	})
}

func TestAccountUpdated(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	// init mongo connection
	appConfig := config.MustRead(runner.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("given some fake account", t, func() {
		acc, err := models.CreateAccountInBothDbs()
		So(acc, ShouldNotBeNil)
		So(err, ShouldBeNil)

		Convey("it should save the document to algolia if not created before", func() {
			err := handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			Convey("it should have email in it", func() {
				// make sure account is there
				So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

				// update user's email
				selector := modelhelper.Selector{"username": acc.Nick}
				updateQuery := modelhelper.Selector{"$set": bson.M{
					"email": models.RandomName() + "@bar.com",
				}}
				err = modelhelper.UpdateUser(selector, updateQuery)
				So(err, ShouldBeNil)

				err = handler.AccountUpdated(acc)
				So(err, ShouldBeNil)

				err = makeSureAccount(handler, acc.OldId, func(record map[string]interface{}, err error) bool {
					if err != nil {
						return false
					}

					if record == nil {
						return false
					}

					return strings.HasSuffix(record["email"].(string), "@bar.com")
				})
				So(err, ShouldBeNil)
			})

		})
	})
}

func doBasicTestForAccount(handler *Controller, id string) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err != nil {
			return false
		}

		if record == nil {
			return false
		}

		return true
	})
}
