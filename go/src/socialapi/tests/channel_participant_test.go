package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"strings"
	"testing"
	"time"

	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelParticipantOperations(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while testing channel participants", t, func() {
			Convey("First Create Users and initiate conversation", func() {
				ownerAccount, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

				secondAccount, err := models.CreateAccountInBothDbs()
				tests.ResultedWithNoErrorCheck(secondAccount, err)
				_, err = groupChannel.AddParticipant(secondAccount.Id)
				So(err, ShouldBeNil)

				thirdAccount, err := models.CreateAccountInBothDbs()
				tests.ResultedWithNoErrorCheck(thirdAccount, err)
				_, err = groupChannel.AddParticipant(thirdAccount.Id)
				So(err, ShouldBeNil)

				forthAccount, err := models.CreateAccountInBothDbs()
				tests.ResultedWithNoErrorCheck(forthAccount, err)
				_, err = groupChannel.AddParticipant(forthAccount.Id)
				So(err, ShouldBeNil)

				devrim, err := models.CreateAccountInBothDbsWithNick("devrim")
				tests.ResultedWithNoErrorCheck(devrim, err)
				_, err = groupChannel.AddParticipant(devrim.Id)
				So(err, ShouldBeNil)

				ses, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
				tests.ResultedWithNoErrorCheck(ses, err)

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
				Convey("First user should be able to invite second user", func() {
					_, err = rest.InviteChannelParticipant(channelContainer.Channel.Id, ownerAccount.Id, secondAccount.Id)
					So(err, ShouldBeNil)
					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)
					// it is four because first user is "devrim" here
					So(len(participants), ShouldEqual, 2)

					Convey("Second user should be able to reject invitation", func() {
						ses, err := models.FetchOrCreateSession(secondAccount.Nick, groupName)
						So(err, ShouldBeNil)
						So(ses, ShouldNotBeNil)

						err = rest.RejectInvitation(channelContainer.Channel.Id, ses.ClientId)
						So(err, ShouldBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 2)
					})

					Convey("Second user should be able to accept invitation", func() {
						ses, err := models.FetchOrCreateSession(secondAccount.Nick, groupName)
						So(err, ShouldBeNil)
						So(ses, ShouldNotBeNil)

						err = rest.AcceptInvitation(channelContainer.Channel.Id, ses.ClientId)
						So(err, ShouldBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerAccount.Id)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 3)
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
				Convey("Users should not be able to add/remove users to/from bot channels", func() {
					ownerAccount, _, groupName := models.CreateRandomGroupDataWithChecks()

					participant := models.NewAccount()
					participant.OldId = AccountOldId.Hex()
					participant, err = rest.CreateAccount(participant)
					So(err, ShouldBeNil)
					So(participant, ShouldNotBeNil)

					ses, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
					So(err, ShouldBeNil)

					ch, err := rest.CreateChannelByGroupNameAndType(ownerAccount.Id, groupName, models.Channel_TYPE_BOT, ses.ClientId)
					So(err, ShouldBeNil)
					So(ch, ShouldNotBeNil)

					_, err = rest.AddChannelParticipant(ch.Id, ownerAccount.Id, participant.Id)
					So(strings.Contains(err.Error(), "can not add participants for bot channel"), ShouldBeTrue)
				})
			})
		})
	})
}
