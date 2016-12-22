package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/request"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"
	"time"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelHistory(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While testing history of a channel", t, func() {
			Convey("We should be able to create it(channel) first", func() {
				groupName := models.RandomGroupName()

				account, err := models.CreateAccountInBothDbsWithNick("sinan")
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)

				ses, err := modelhelper.FetchOrCreateSession(account.Nick, groupName)
				So(err, ShouldBeNil)
				So(ses, ShouldNotBeNil)

				channel := models.CreateTypedGroupedChannelWithTest(
					account.Id,
					models.Channel_TYPE_GROUP,
					groupName,
				)
				_, err = channel.AddParticipant(account.Id)
				So(err, ShouldBeNil)

				Convey("While posting a new message to it", func() {
					var channelParticipant *models.ChannelParticipant
					var err error
					Convey("We should be able to create a participant first", func() {
						channelParticipant, err = rest.CreateChannelParticipant(channel.Id, ses.ClientId)
						So(err, ShouldBeNil)
						So(channelParticipant, ShouldNotBeNil)

						Convey("Create posts with created participant", func() {
							channel := channel
							for i := 0; i < 10; i++ {
								post, err := rest.CreatePost(channel.Id, ses.ClientId)
								So(err, ShouldBeNil)
								So(post, ShouldNotBeNil)
								So(post.Id, ShouldNotEqual, 0)
								So(post.Body, ShouldNotEqual, "")

							}
							Convey("We should be able to fetch the history", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										AccountId: account.Id,
									},
									ses.ClientId,
								)
								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 10)
							})

							Convey("We should be not able to fetch the history if the clientId is not set", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										AccountId: account.Id,
									},
									"",
								)
								So(err, ShouldNotBeNil)
								So(history, ShouldBeNil)
							})

							Convey("We should be not able to fetch the history if the clientId doesnt exist", func() {

								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										AccountId: account.Id,
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
						Convey("We should be able to check history according to request", func() {
							channel := channel
							for i := 0; i < 5; i++ {
								body := fmt.Sprintf("body%d", i)
								post, err := rest.CreatePostWithBodyAndAuth(channel.Id, body, ses.ClientId)
								// we need to wait while posting messages
								// if we dont use time sleep, Added_at field of the messages is
								// gonna be equal and this behavior is not expected situation
								// Then, tests will not be worked correctly
								time.Sleep(1000 * time.Millisecond)
								So(err, ShouldBeNil)
								So(post, ShouldNotBeNil)
								So(post.Id, ShouldNotEqual, 0)
								So(post.Body, ShouldNotEqual, "")
							}
							bodyMes := "postMid message"
							postMid, err := rest.CreatePostWithBodyAndAuth(channel.Id, bodyMes, ses.ClientId)
							So(postMid, ShouldNotBeNil)
							So(err, ShouldBeNil)
							for i := 5; i < 10; i++ {
								time.Sleep(1000 * time.Millisecond)
								body := fmt.Sprintf("body%d", i)
								post, err := rest.CreatePostWithBodyAndAuth(channel.Id, body, ses.ClientId)
								So(err, ShouldBeNil)
								So(post, ShouldNotBeNil)
								So(post.Id, ShouldNotEqual, 0)
								So(post.Body, ShouldNotEqual, "")
							}
							Convey("We should able to fetch the history with query request ", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										AccountId: account.Id,
									},
									ses.ClientId,
								)

								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 11)
							})

							Convey("We should able to fetch the history with query ADDED AT & ASC ", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										From:      postMid.CreatedAt,
										SortOrder: "ASC",
									},
									ses.ClientId,
								)

								var historyArr []string
								arr := []string{"postMid message", "body5", "body6", "body7", "body8", "body9"}
								for _, x := range history.MessageList {
									historyArr = append(historyArr, x.Message.Body)
								}
								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 6)
								So(arr, ShouldResemble, historyArr)
							})

							Convey("We should able to fetch the history with query ADDED AT & DESC ", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										From:      postMid.CreatedAt,
										SortOrder: "DESC",
									},
									ses.ClientId,
								)

								var historyArr []string
								arr := []string{"body4", "body3", "body2", "body1", "body0"}
								for _, x := range history.MessageList {
									historyArr = append(historyArr, x.Message.Body)
								}
								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 5)
								So(arr, ShouldResemble, historyArr)
							})
							Convey("We should able to fetch the with query ADDED AT & DESC ORDER& LIMIT ", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										From:      postMid.CreatedAt,
										SortOrder: "DESC",
										Limit:     3,
									},
									ses.ClientId,
								)

								var historyArr []string
								arr := []string{"body4", "body3", "body2"}
								for _, x := range history.MessageList {
									historyArr = append(historyArr, x.Message.Body)
								}
								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 3)
								So(arr, ShouldResemble, historyArr)
							})
							Convey("We should able to fetch the with query ADDED AT & ASC ORDER& LIMIT ", func() {
								history, err := rest.GetHistory(
									channel.Id,
									&request.Query{
										From:      postMid.CreatedAt,
										SortOrder: "ASC",
										Limit:     3,
									},
									ses.ClientId,
								)

								var historyArr []string
								arr := []string{"postMid message", "body5", "body6"}
								for _, x := range history.MessageList {
									historyArr = append(historyArr, x.Message.Body)
								}
								So(err, ShouldBeNil)
								So(history, ShouldNotBeNil)
								So(len(history.MessageList), ShouldEqual, 3)
								So(arr, ShouldResemble, historyArr)
							})
						})
					})
				})
			})
		})
	})
}
