package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelHistory(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("While testing history of a channel", t, func() {
		var channel *models.Channel
		Convey("We should be able to create it(channel) first", func() {
			account, err := models.CreateAccountInBothDbs()
			So(err, ShouldBeNil)
			So(account, ShouldNotBeNil)

			channel, err = rest.CreateChannel(account.Id)
			So(err, ShouldBeNil)
			So(channel, ShouldNotBeNil)
			Convey("While posting a new message to it", func() {
				var channelParticipant *models.ChannelParticipant
				var err error
				Convey("We should be able to create a participant first", func() {
					channelParticipant, err = rest.CreateChannelParticipant(channel.Id, account.Id)
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

							ses, err := models.FetchOrCreateSession(account.Nick)
							So(err, ShouldBeNil)
							So(ses, ShouldNotBeNil)

							history, err := rest.GetHistory(
								channel.Id,
								&request.Query{
									AccountId: channelParticipant.AccountId,
								},
								ses.ClientId,
							)
							So(err, ShouldBeNil)
							So(history, ShouldNotBeNil)
							So(len(history.MessageList), ShouldEqual, 10)
						})
						Convey("We should be not able to fetch the history if the clientId is not set", func() {

							ses, err := models.FetchOrCreateSession(account.Nick)
							So(err, ShouldBeNil)
							So(ses, ShouldNotBeNil)

							history, err := rest.GetHistory(
								channel.Id,
								&request.Query{
									AccountId: channelParticipant.AccountId,
								},
								"",
							)
							So(err, ShouldNotBeNil)
							So(history, ShouldBeNil)
						})

						Convey("We should be not able to fetch the history if the clientId doesnt exist", func() {

							ses, err := models.FetchOrCreateSession(account.Nick)
							So(err, ShouldBeNil)
							So(ses, ShouldNotBeNil)

							history, err := rest.GetHistory(
								channel.Id,
								&request.Query{
									AccountId: channelParticipant.AccountId,
								},
								"foobarzaa",
							)

							So(err, ShouldNotBeNil)
							So(history, ShouldBeNil)
						})

						Convey("We should be able to get channel message count", func() {
							count, err := rest.CountHistory(channel.Id)
							So(err, ShouldBeNil)
							So(count, ShouldNotBeNil)
							So(count.TotalCount, ShouldEqual, 10)
						})
					})
				})
			})
		})
	})
}
