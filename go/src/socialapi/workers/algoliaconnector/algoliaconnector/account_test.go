package algoliaconnector

import (
	"socialapi/models"
	"testing"

	"labix.org/v2/mgo/bson"

	. "github.com/smartystreets/goconvey/convey"
)

func TestAccountSaved(t *testing.T) {
	runner, handler := getTestHandler()
	defer runner.Close()

	Convey("given some fake account", t, func() {
		mockAccount := &models.Account{
			OldId:   bson.NewObjectId().Hex(),
			Id:      100000000,
			Nick:    "fake-nickname",
			IsTroll: false,
		}
		Convey("it should save the document to algolia", func() {
			err := handler.AccountCreated(mockAccount)
			So(err, ShouldBeNil)
		})
	})
}
