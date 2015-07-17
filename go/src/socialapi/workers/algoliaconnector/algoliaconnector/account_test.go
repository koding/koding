package algoliaconnector

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
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

				user, err := modelhelper.GetUser(acc.Nick)
				So(err, ShouldBeNil)

				err = makeSureWithSearch(
					handler,
					IndexAccounts,
					user.Email,
					map[string]interface{}{"restrictSearchableAttributes": "email"},
					func(record map[string]interface{}, err error) bool {
						if err != nil {
							return false
						}

						if record == nil {
							return false
						}

						hits, ok := record["nbHits"]
						if hits == nil || !ok {
							return false
						}

						if hits.(float64) <= 0 {
							return false
						}

						return true
					},
				)

				So(err, ShouldBeNil)
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
				selector := bson.M{"username": acc.Nick}
				newEmail := models.RandomGroupName() + "@bar.com"
				updateQuery := bson.M{"email": newEmail}
				err = modelhelper.UpdateUser(selector, updateQuery)
				So(err, ShouldBeNil)

				err = handler.AccountUpdated(acc)
				So(err, ShouldBeNil)

				err = makeSureWithSearch(
					handler,
					IndexAccounts,
					newEmail,
					map[string]interface{}{"restrictSearchableAttributes": "email"},
					func(record map[string]interface{}, err error) bool {
						if err != nil {
							return false
						}

						if record == nil {
							return false
						}

						hits, ok := record["nbHits"]
						if hits == nil || !ok {
							return false
						}

						if hits.(float64) <= 0 {
							return false
						}

						return true
					})
				So(err, ShouldBeNil)
			})
		})

		Convey("it should delete the document when user account is deleted", func() {
			// first ensure account object is created
			err = handler.AccountCreated(acc)
			So(err, ShouldBeNil)
			So(doBasicTestForAccount(handler, acc.OldId), ShouldBeNil)

			newNick := "guest-" + models.RandomName() + "-rm"
			err = models.UpdateUsernameInBothDbs(acc.Nick, newNick)
			So(err, ShouldBeNil)

			acc.Nick = newNick

			err = handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			So(doBasicTestForAccountDeletion(handler, acc.OldId), ShouldBeNil)
		})

		Convey("it should not return any error when deleted user does not exist on Algolia", func() {
			newNick := "guest-" + models.RandomName() + "-rm"
			err = models.UpdateUsernameInBothDbs(acc.Nick, newNick)
			So(err, ShouldBeNil)

			acc.Nick = newNick

			err = handler.AccountUpdated(acc)
			So(err, ShouldBeNil)

			So(doBasicTestForAccountDeletion(handler, acc.OldId), ShouldBeNil)
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

func doBasicTestForAccountDeletion(handler *Controller, id string) error {
	return makeSureAccount(handler, id, func(record map[string]interface{}, err error) bool {
		if err == nil {
			return false
		}

		return true
	})
}
