package main

import (
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

// var AccountOldId = bson.NewObjectId()

func TestChannelDelete(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  creating account", t, func() {
			Convey("First Create User", func() {
				Convey("Should not error if you pass old id", func() {
					channel, accounts := models.CreateChannelWithParticipants()
					So(channel, ShouldNotBeNil)
					So(accounts, ShouldNotBeNil)
					err := models.DeleteChannelsIfGroupNotInMongo()
					So(err, ShouldBeNil)
				})
			})
		})
	})
}

//
// func accountCreatorWithCount(count int) error {
// 	for i := 0; i < count; i++ {
// 		account := models.NewAccount()
// 		account.OldId = bson.NewObjectId().Hex()
// 		account, err := rest.CreateAccount(account)
// 		if err != nil {
// 			return err
// 		}
// 	}
// 	return nil
// }
