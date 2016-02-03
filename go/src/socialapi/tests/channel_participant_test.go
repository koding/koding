package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"strings"
	"testing"
	"time"

	"github.com/cihangir/nisql"
	"github.com/koding/bongo"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestChannelParticipantOperations(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("while testing channel participants", t, func() {
			Convey("First Create Users and initiate conversation", func() {
				ownerAccount, groupChannel, groupName := models.CreateRandomGroupDataWithChecks()

				ownerSes, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
				So(err, ShouldBeNil)
				So(ownerSes, ShouldNotBeNil)

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

				secondSes, err := models.FetchOrCreateSession(secondAccount.Nick, groupName)
				tests.ResultedWithNoErrorCheck(secondSes, err)

				pmr := models.ChannelRequest{}

				pmr.AccountId = ownerAccount.Id

				pmr.Body = "new conversation"
				pmr.GroupName = groupName
				pmr.Recipients = []string{"devrim"}

				channelContainer, err := rest.SendPrivateChannelRequest(pmr, ownerSes.ClientId)
				So(err, ShouldBeNil)
				So(channelContainer, ShouldNotBeNil)

				Convey("First user should be able to add second and third users to conversation", func() {
					_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id, thirdAccount.Id)
					So(err, ShouldBeNil)
					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
					So(err, ShouldBeNil)
					So(participants, ShouldNotBeNil)
					// it is four because first user is "devrim" here
					So(len(participants), ShouldEqual, 4)

					Convey("First user should not be able to re-add second participant", func() {
						_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
						So(err, ShouldBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 4)
					})

					Convey("Second user should be able to leave conversation", func() {
						// token of account -> secondAccount
						_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, secondSes.ClientId, secondAccount.Id)
						So(err, ShouldBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 3)

						Convey("A user who is not participant of a conversation should not be able to add another user to the conversation", func() {
							_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, secondSes.ClientId, forthAccount.Id)
							So(err, ShouldNotBeNil)

							participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
							So(err, ShouldBeNil)
							So(participants, ShouldNotBeNil)
							So(len(participants), ShouldEqual, 3)
						})
					})

					Convey("Channel owner should be able to kick another conversation participant", func() {
						_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
						So(err, ShouldBeNil)

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
						So(err, ShouldBeNil)
						So(participants, ShouldNotBeNil)
						So(len(participants), ShouldEqual, 3)
					})

					Convey("when a user is blocked", func() {
						_, err = rest.BlockChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
						So(err, ShouldBeNil)

						Convey("it should not be in channel participant list", func() {
							participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
							So(err, ShouldBeNil)
							So(participants, ShouldNotBeNil)
							So(len(participants), ShouldEqual, 3)
						})

						Convey("should not be able to add it back", func() {
							_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
							So(err, ShouldNotBeNil)
						})

						Convey("should be able to unblock", func() {
							_, err = rest.UnblockChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
							So(err, ShouldBeNil)

							Convey("it should not be in channel participant list still", func() {
								participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
								So(err, ShouldBeNil)
								So(participants, ShouldNotBeNil)
								So(len(participants), ShouldEqual, 3)
							})

							Convey("when we add the same user as participant", func() {
								_, err = rest.AddChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id, thirdAccount.Id)
								So(err, ShouldBeNil)

								Convey("it should be in channel participant list", func() {
									participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
									So(err, ShouldBeNil)
									So(participants, ShouldNotBeNil)
									So(len(participants), ShouldEqual, 4)
								})
							})
						})
					})

					Convey("Second user should not be able to kick another conversation participant", func() {
						_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, secondSes.ClientId, thirdAccount.Id)
						So(err, ShouldNotBeNil)
					})

				})
				Convey("First user should be able to invite second user", func() {
					_, err = rest.InviteChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, secondAccount.Id)
					So(err, ShouldBeNil)
					participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
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

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
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

						participants, err := rest.ListChannelParticipants(channelContainer.Channel.Id, ownerSes.ClientId)
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

					_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, ses.ClientId, account.Id)
					So(err, ShouldBeNil)

					_, err = rest.DeleteChannelParticipant(channelContainer.Channel.Id, ownerSes.ClientId, ownerAccount.Id)
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

					// account is -> ownerAccount.Id
					_, err = rest.AddChannelParticipant(ch.Id, ses.ClientId, participant.Id)
					So(strings.Contains(err.Error(), "can not add participants for bot channel"), ShouldBeTrue)
				})

				Convey("Users should be able to add/remove users to/from topic channels", func() {
					ownerAccount, _, groupName := models.CreateRandomGroupDataWithChecks()

					participant := models.NewAccount()
					participant.OldId = AccountOldId.Hex()
					participant, err = rest.CreateAccount(participant)
					So(err, ShouldBeNil)
					So(participant, ShouldNotBeNil)

					ses, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
					So(err, ShouldBeNil)

					ch, err := rest.CreateChannelByGroupNameAndType(ownerAccount.Id, groupName, models.Channel_TYPE_TOPIC, ses.ClientId)
					So(err, ShouldBeNil)
					So(ch, ShouldNotBeNil)

					// account is -> ownerAccount.Id
					_, err = rest.AddChannelParticipant(ch.Id, ses.ClientId, participant.Id)
					So(err, ShouldBeNil)

					Convey("adding same user again should success", func() {
						_, err = rest.AddChannelParticipant(ch.Id, ses.ClientId, participant.Id)
						So(err, ShouldBeNil)
					})

					_, err = rest.DeleteChannelParticipant(ch.Id, ses.ClientId, participant.Id)
					So(err, ShouldBeNil)

					Convey("removing same user again should success", func() {
						_, err = rest.DeleteChannelParticipant(ch.Id, ses.ClientId, participant.Id)
						So(err, ShouldBeNil)
					})
				})
				Convey("User's notification setting should be removed when user left from channel", func() {
					ownerAccount, _, groupName := models.CreateRandomGroupDataWithChecks()

					account := models.NewAccount()
					account.OldId = AccountOldId.Hex()
					account, err = rest.CreateAccount(account)
					So(err, ShouldBeNil)
					So(account, ShouldNotBeNil)

					_, err := models.FetchOrCreateSession(ownerAccount.Nick, groupName)
					So(err, ShouldBeNil)

					ses, err := models.FetchOrCreateSession(account.Nick, groupName)
					So(err, ShouldBeNil)
					So(ses, ShouldNotBeNil)

					channel := models.CreateTypedGroupedChannelWithTest(
						account.Id,
						models.Channel_TYPE_GROUP,
						groupName,
					)
					_, err = channel.AddParticipant(account.Id)
					So(err, ShouldBeNil)

					// create notification setting with fields
					n := &models.NotificationSetting{
						ChannelId:      channel.Id,
						AccountId:      account.Id,
						DesktopSetting: nisql.NullString{},
						MobileSetting:  nisql.String(models.NotificationSetting_STATUS_PERSONAL),
						IsMuted:        nisql.NullBool{},
						IsSuppressed:   nisql.Bool(true),
					}
					ns, err := rest.CreateNotificationSetting(n, ses.ClientId)
					So(err, ShouldBeNil)
					So(ns.AccountId, ShouldEqual, account.Id)
					So(*ns.IsSuppressed.Get(), ShouldEqual, true)
					So(ns.IsMuted.Get(), ShouldEqual, nil)
					So(ns.DesktopSetting.Get(), ShouldEqual, nil)

					Convey("Notification settings should be removed after participant removed", func() {
						// we can get notification settings before removing accoung from channel
						ns, err := rest.GetNotificationSetting(channel.Id, ses.ClientId)
						So(err, ShouldBeNil)
						So(ns, ShouldNotBeNil)

						err = channel.RemoveParticipant(account.Id)
						So(err, ShouldBeNil)

						// after removing account from channel, we should not be able to get notification setting
						ns, err = rest.GetNotificationSetting(channel.Id, ses.ClientId)
						So(err, ShouldNotBeNil)
						So(err.Error(), ShouldContainSubstring, models.ErrAccountIsNotParticipant.Error())
						So(ns, ShouldBeNil)
					})
				})
			})
		})
	})
}
