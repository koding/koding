package main

import (
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

// var AccountOldId = bson.NewObjectId()

func TestChannelDeleteWithPostgreRecord(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  creating account", t, func() {
			Convey("First Create User", func() {
				Convey("channel creation should be successfully", func() {
					channel, accounts := createChannelWithParticipants("Group_Only_postgre")
					So(channel, ShouldNotBeNil)
					So(accounts, ShouldNotBeNil)
					Convey("participant should be in the channel", func() {
						participants, err := channel.FetchChannelParticipants()
						So(err, ShouldBeNil)
						So(len(participants), ShouldBeGreaterThan, 0)
					})
					Convey("channel deletion should be successfully if groups are not in mongodb", func() {
						err := models.DeleteChannelsIfGroupNotInMongo()
						So(err, ShouldBeNil)
						Convey("participants&channel should not be in postgres", func() {
							_, err := channel.FetchChannelParticipants()
							So(err, ShouldNotBeNil)
							So(err, ShouldEqual, bongo.RecordNotFound)
							fetchedChannels, err := models.NewChannel().FetchByIds([]int64{channel.Id})
							So(err, ShouldBeNil)
							So(len(fetchedChannels), ShouldEqual, 0)
						})
					})
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
