package tests

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

func TestTrollModeSetting(t *testing.T) {
	var AccountOldId = bson.NewObjectId()
	Convey("while testing troll mode", t, func() {
		Convey("First Create User", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err := rest.CreateAccount(account)
			tests.ResultedWithNoErrorCheck(account, err)

			Convey("then we should be able to mark as troll", func() {
				res := rest.MarkAsTroll(account)
				So(res, ShouldBeNil)
				Convey("sholdnt be able to mark as troll twice", func() {
					res := rest.MarkAsTroll(account)
					So(res, ShouldNotBeNil)
				})
			})

			Convey("should be able to unmark as troll", func() {
				res := rest.UnMarkAsTroll(account)
				So(res, ShouldBeNil)
				Convey("should not be able to unmark as troll twice", func() {
					res := rest.UnMarkAsTroll(account)
					So(res, ShouldNotBeNil)
				})
			})
		})
	})
}
