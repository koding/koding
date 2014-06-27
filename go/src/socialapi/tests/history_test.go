package main

import (
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelHistory(t *testing.T) {
	Convey("While testing history of a channel", t, func() {
		var channel *models.Channel
		var err error
		Convey("We should be able to create it(channel) first", func() {
			account := models.NewAccount()
			account.OldId = AccountOldId.Hex()
			account, err = rest.CreateAccount(account)
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel, err = rest.CreateChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			Convey("While posting a new message to it", func() {
				var channelParticipant *models.ChannelParticipant
				var err error
				Convey("We should be able to create a participant first", func() {
					channelParticipant, err = rest.CreateChannelParticipant(channel.Id)
					So(err, ShouldBeNil)
					So(channelParticipant, ShouldNotBeNil)

					Convey("Create posts with created participant", func() {
						channel := channel
						for i := 0; i < 10; i++ {
							post, err := rest.CreatePost(channel.Id, channelParticipant.AccountId)
							So(err, ShouldBeNil)
							So(post, ShouldNotBeNil)
							So(post.Id, ShouldNotEqual, 0)
							So(post.Body, ShouldNotEqual, "")

						}
						Convey("We should be able to fetch the history", func() {
							history, err := rest.GetHistory(channel.Id, &request.Query{AccountId: channelParticipant.AccountId})
							So(err, ShouldBeNil)
							So(history, ShouldNotBeNil)
							So(len(history.MessageList), ShouldEqual, 10)
						})
					})
				})
			})
		})
	})
}
