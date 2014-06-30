package tests

import (
	"math/rand"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"strconv"
	"testing"
	"time"

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

func TestTrollModeActivityFeed(t *testing.T) {
	Convey("while testing troll mode activity listing", t, func() {
		var adminUserOldId = bson.NewObjectId()
		var normalUserOldId1 = bson.NewObjectId()
		var normalUserOldId2 = bson.NewObjectId()
		var trollUserOldId = bson.NewObjectId()

		adminUser := models.NewAccount()
		adminUser.OldId = adminUserOldId.Hex()
		adminUser, err := rest.CreateAccount(adminUser)
		tests.ResultedWithNoErrorCheck(adminUser, err)

		normalUser1 := models.NewAccount()
		normalUser1.OldId = normalUserOldId1.Hex()
		normalUser1, err = rest.CreateAccount(normalUser1)
		tests.ResultedWithNoErrorCheck(normalUser1, err)

		normalUser2 := models.NewAccount()
		normalUser2.OldId = normalUserOldId2.Hex()
		normalUser2, err = rest.CreateAccount(normalUser2)
		tests.ResultedWithNoErrorCheck(normalUser2, err)

		trollUser := models.NewAccount()
		trollUser.OldId = trollUserOldId.Hex()
		trollUser, err = rest.CreateAccount(trollUser)
		tests.ResultedWithNoErrorCheck(trollUser, err)

		So(rest.MarkAsTroll(trollUser), ShouldBeNil)

		rand.Seed(time.Now().UnixNano())
		groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)
		groupChannel, err := rest.CreateChannelByGroupNameAndType(
			adminUser.Id,
			groupName,
			models.Channel_TYPE_GROUP,
		)

		tests.ResultedWithNoErrorCheck(groupChannel, err)

		Convey("troll users should be able to post status update", func() {
			Convey("troll users should be able to see his status update", func() {
				// create post
				post, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
				tests.ResultedWithNoErrorCheck(post, err)

				history, err := rest.GetHistory(groupChannel.Id, &request.Query{AccountId: trollUser.Id, ShowExempt: true})
				tests.ResultedWithNoErrorCheck(history, err)
				So(len(history.MessageList), ShouldEqual, 1)
			})
			Convey("normal user should not be able to see troll's status update", func() {
				// create post
				post, err := rest.CreatePost(groupChannel.Id, trollUser.Id)
				tests.ResultedWithNoErrorCheck(post, err)

				history, err := rest.GetHistory(groupChannel.Id, &request.Query{AccountId: trollUser.Id})
				tests.ResultedWithNoErrorCheck(history, err)
				So(len(history.MessageList), ShouldEqual, 0)
				// So(len(history.MessageList), ShouldEqual, 0)
			})
		})

		Convey("should be able to unmark as troll", func() {})
	})
}
