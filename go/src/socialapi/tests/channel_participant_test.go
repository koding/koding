package main

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/config"
	"socialapi/models"
	"socialapi/rest"
	"strconv"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelParticipantOperations(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while testing channel participants", t, func() {

		Convey("First Create Users and initiate conversation", func() {
			var err error
			ownerAccount := models.NewAccount()
			ownerAccount.OldId = AccountOldId.Hex()
			ownerAccount, err = rest.CreateAccount(ownerAccount)
			So(err, ShouldBeNil)
			So(ownerAccount, ShouldNotBeNil)

			secondAccount := models.NewAccount()
			secondAccount.OldId = AccountOldId2.Hex()
			secondAccount, err = rest.CreateAccount(secondAccount)
			So(err, ShouldBeNil)
			So(secondAccount, ShouldNotBeNil)

			thirdAccount := models.NewAccount()
			thirdAccount.OldId = AccountOldId3.Hex()
			thirdAccount, err = rest.CreateAccount(thirdAccount)
			So(err, ShouldBeNil)
			So(thirdAccount, ShouldNotBeNil)

			forthAccount := models.NewAccount()
			forthAccount.OldId = AccountOldId4.Hex()
			forthAccount, err = rest.CreateAccount(forthAccount)
			So(err, ShouldBeNil)
			So(forthAccount, ShouldNotBeNil)

			CreatePrivateChannelUser("devrim")

			groupName := "testgroup" + strconv.FormatInt(rand.Int63(), 10)

			pmr := models.PrivateChannelRequest{}

			pmr.AccountId = ownerAccount.Id

			pmr.Body = "new conversation"
			pmr.GroupName = groupName
			pmr.Recipients = []string{"devrim"}

			channelContainer, err := rest.SendPrivateChannelRequest(pmr)
			So(err, ShouldBeNil)
			So(channelContainer, ShouldNotBeNil)

			Convey("First user should be able to add second and third users to conversation", func() {
				_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id, thirdAccount.Id)
				So(err, ShouldBeNil)
				participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
				So(err, ShouldBeNil)
				So(participants, ShouldNotBeNil)
				// it is four because first user is "devrim" here
				So(len(participants), ShouldEqual, 4)

				Convey("First user should not be able to re-add second participant", func() {
					_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
					So(err, ShouldBeNil)

					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)
					So(len(participants), ShouldEqual, 4)
				})

				Convey("Second user should be able to leave conversation", func() {
					_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, secondAccount.Id, secondAccount.Id)
					So(err, ShouldBeNil)

					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)
					So(len(participants), ShouldEqual, 3)

					Convey("A user who is not participant of a conversation should not be able to add another user to the conversation", func() {
						_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, secondAccount.Id, forthAccount.Id)
						So(err, ShouldNotBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 3)
					})
				})

				Convey("Channel owner should be able to kick another conversation participant", func() {
					_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
					So(err, ShouldBeNil)

					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)
					So(len(participants), ShouldEqual, 3)
				})

				Convey("when a user is blocked", func() {
					_, err = rest.BlockChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
					So(err, ShouldBeNil)

					Convey("it should not be in channel participant list", func() {
						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 3)
					})

					Convey("should not be able to add it back", func() {
						_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
						So(err, ShouldNotBeNil)
					})

					Convey("should be able to unblock", func() {
						_, err = rest.UnblockChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
						So(err, ShouldBeNil)

						Convey("it should not be in channel participant list still", func() {
							participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
							So(err, ShouldBeNil)
							So(participants, ShouldNotBeNil)
							So(len(participants), ShouldEqual, 3)
						})

						Convey("when we add the same user as participant", func() {
							_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id, thirdAccount.Id)
							So(err, ShouldBeNil)

							Convey("it should be in channel participant list", func() {
								participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
								So(err, ShouldBeNil)
								So(participants, ShouldNotBeNil)
								So(len(participants), ShouldEqual, 4)
							})
						})
					})
				})

				Convey("Second user should not be able to kick another conversation participant", func() {
					_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, secondAccount.Id, thirdAccount.Id)
					So(err, ShouldNotBeNil)
				})
			})

			// TODO Until we find a better way for handling async stuff, this test is skipped. Instead of sleep, we should use some
			// timeouts for testing these kind of stuff.
			SkipConvey("All private messages must be deleted when all participant users leave the channel", func() {
				account := models.NewAccount()
				err = account.ByNick("devrim")
				So(err, ShouldBeNil)

				_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, account.Id, account.Id)
				So(err, ShouldBeNil)

				_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, ownerAccount.Id)
				So(err, ShouldBeNil)

				time.Sleep(1 * time.Second)

				testChannel := models.NewChannel()
				err := testChannel.ById(channelContainer.Channel.Id)
				So(err, ShouldEqual, bongo.RecordNotFound)

				testChannelList := models.NewChannelMessageList()
				err = bongo.B.Unscoped().Where("channel_id = ?", channelContainer.Channel.Id).Find(testChannelList).Error
				So(err, ShouldEqual, bongo.RecordNotFound)

				testMessage := models.NewChannelMessage()
				err = bongo.B.Unscoped().Where("initial_channel_id = ?", channelContainer.Channel.Id).Find(testMessage).Error
				So(err, ShouldEqual, bongo.RecordNotFound)
			})
		})
	})
}
