package main

import (
	"socialapi/models"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/bongo"
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

func TestChannelDeleteInBothDB(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while  creating account", t, func() {
			Convey("First Create User", func() {
				Convey("channel creation in both db should be successfully", func() {
					groupName := "Groups_Mongo_Postgre"
					channel, account := createGroupDataWithChecksInBothDB(groupName)
					So(channel, ShouldNotBeNil)
					So(account, ShouldNotBeNil)
					Convey("participant should be in the channel", func() {
						participants, err := channel.FetchChannelParticipants()
						So(err, ShouldBeNil)
						So(len(participants), ShouldBeGreaterThan, 0)
					})
					Convey("channel should not be deleted if groups are not in both db", func() {
						err := models.DeleteChannelsIfGroupNotInMongo()
						So(err, ShouldBeNil)
						Convey("participants&channel should not be in postgres", func() {
							participants, err := channel.FetchChannelParticipants()
							So(err, ShouldBeNil)
							So(len(participants), ShouldBeGreaterThan, 0)
							fetchedChannels, err := models.NewChannel().FetchByIds([]int64{channel.Id})
							So(err, ShouldBeNil)
							So(len(fetchedChannels), ShouldBeGreaterThan, 0)
						})
					})
				})
			})
		})
	})
}

func createChannelWithParticipants(groupName string) (*models.Channel, []*models.Account) {
	account1 := models.CreateAccountWithTest()
	account2 := models.CreateAccountWithTest()
	account3 := models.CreateAccountWithTest()
	accounts := []*models.Account{account1, account2, account3}

	channel := models.CreateTypedGroupedChannelWithTest(account1.Id, models.Channel_TYPE_DEFAULT, groupName)
	models.AddParticipantsWithTest(channel.Id, account1.Id, account2.Id, account3.Id)

	return channel, accounts
}

func createGroupDataWithChecksInBothDB(groupName string) (*models.Channel, *models.Account) {
	account := models.CreateAccountInBothDbsWithCheck()

	groupChannel := models.CreateTypedGroupedChannelWithTest(
		account.Id,
		models.Channel_TYPE_GROUP,
		groupName,
	)

	_, err := groupChannel.AddParticipant(account.Id)
	So(err, ShouldBeNil)

	// we recommend you to not ignore errors.
	// In this case we need to try to create same named group in mongo.
	// then it gives key duplication error, so err checking is disabled here.
	models.CreateGroupInMongo(groupName, groupChannel.Id)

	return groupChannel, account
}
