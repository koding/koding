package main

import (
	socialapimodels "socialapi/models"
	"socialapi/rest"
	"socialapi/workers/notification/models"
	"testing"
	"time"
	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	cacheEnabled     = false
	ownerAccount     socialapimodels.Account
	firstUser        socialapimodels.Account
	secondUser       socialapimodels.Account
	thirdUser        socialapimodels.Account
	forthUser        socialapimodels.Account
	testGroupChannel socialapimodels.Channel
	firstMessage     *socialapimodels.ChannelMessage
)

const SLEEP_TIME = 4

func TestNotificationCreation(t *testing.T) {
	ownerAccount := socialapimodels.NewAccount()
	firstUser := socialapimodels.NewAccount()
	secondUser := socialapimodels.NewAccount()
	thirdUser := socialapimodels.NewAccount()
	forthUser := socialapimodels.NewAccount()
	testGroupChannel := socialapimodels.NewChannel()

	testCases := func() {
		Convey("First create users and required channel", func() {
			Convey("We should be able to create accounts", func() {
				var err error

				// ownerAccount.OldId = "5307f2ce1d10ce614e000003" //can
				ownerAccount.Id = 0
				ownerAccount.OldId = bson.NewObjectId().Hex()
				ownerAccount, err = rest.CreateAccount(ownerAccount)
				ResultedWithNoErrorCheck(ownerAccount, err)

				// firstUser.OldId = "5196fcb0bc9bdb0000000011" //devrim
				firstUser.Id = 0
				firstUser.OldId = bson.NewObjectId().Hex()
				firstUser, err = rest.CreateAccount(firstUser)
				ResultedWithNoErrorCheck(firstUser, err)

				// secondUser.OldId = "5196fcb0bc9bdb0000000012" //sinan
				secondUser.Id = 0
				secondUser.OldId = bson.NewObjectId().Hex()
				secondUser, err = rest.CreateAccount(secondUser)
				ResultedWithNoErrorCheck(secondUser, err)

				// thirdUser.OldId = "5196fcb0bc9bdb0000000013" //chris
				thirdUser.Id = 0
				thirdUser.OldId = bson.NewObjectId().Hex()
				thirdUser, err = rest.CreateAccount(thirdUser)
				ResultedWithNoErrorCheck(thirdUser, err)

				// forthUser.OldId = "5196fcb0bc9bdb0000000014" //richard
				forthUser.Id = 0
				forthUser.OldId = bson.NewObjectId().Hex()
				forthUser, err = rest.CreateAccount(forthUser)
				ResultedWithNoErrorCheck(forthUser, err)
			})

			Convey("We should be able to create notification_test group channel", func() {
				var err error
				name := "notification_test_" + socialapimodels.RandomName()
				testGroupChannel, err = rest.CreateGroupActivityChannel(ownerAccount.Id, name)
				ResultedWithNoErrorCheck(testGroupChannel, err)
			})
		})

		Convey("As a message owner I want to receive reply notifications", func() {

			var replyMessage *socialapimodels.ChannelMessage
			Convey("I should be able to create channel message", func() {
				messageBody := "notification first message"
				var err error
				firstMessage, err = rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(firstMessage, err)
			})

			Convey("First user should be able to reply it", func() {
				var err error
				replyMessage, err = rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

			Convey("First user should not be able to receive any notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should not contain any notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 0)
				})
			})

			Convey("First user should be able to reply it again", func() {
				var err error
				replyMessage, err = rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

			Convey("First user still should not be able to receive any notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should not contain any notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 0)
				})
			})

			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})

				Convey("And Unread notification count should be 1 ", func() {
					So(nl.UnreadCount, ShouldEqual, 1)
				})

			})
		})

		Convey("Second user should be able to reply it", func() {
			replyMessage, err := rest.AddReply(firstMessage.Id, secondUser.Id, testGroupChannel.Id)
			ResultedWithNoErrorCheck(replyMessage, err)
			time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("And Notification list should contain one notification", func() {
				So(len(nl.Notifications), ShouldEqual, 1)
			})
			Convey("Notifier count should be 2", func() {
				So(len(nl.Notifications), ShouldEqual, 1)
				So(nl.Notifications[0].ActorCount, ShouldEqual, 2)
			})

			Convey("Notification should contain second and first user consecutively", func() {
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, firstUser.Id)
			})

		})

		Convey("First user should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)

			Convey("And Notification list should contain one notification", func() {
				So(len(nl.Notifications), ShouldEqual, 1)
				Convey("Notifier count should be 1", func() {
					So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
				})
				Convey("Notification should contain second user", func() {
					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
				})
			})

		})

		Convey("Third user should be able to reply it", func() {
			replyMessage, err := rest.AddReply(firstMessage.Id, thirdUser.Id, testGroupChannel.Id)
			ResultedWithNoErrorCheck(replyMessage, err)
			time.Sleep(4 * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("Notifier count should be 3", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 3)
			})

			Convey("Notification should contain third, second and first user consecutively", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)
				So(nl.Notifications[0].LatestActors[2], ShouldEqual, firstUser.Id)
			})
		})

		Convey("First user should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)

			Convey("And Notification list should contain one notification", func() {
				So(len(nl.Notifications), ShouldEqual, 1)
			})
			Convey("Notifier count should be 2", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 2)
			})

			Convey("Notification should contain third and second user consecutively", func() {
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)
			})

		})

		Convey("Second user should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(secondUser.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)

			Convey("And Notification list should contain one notification", func() {
				So(len(nl.Notifications), ShouldEqual, 1)
			})
			// because it must only see the notifiers after him
			Convey("Notifier count should be 1", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
			})

			Convey("Notification should contain third user only", func() {
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
			})

		})

		Convey("Forth user should be able to reply it", func() {
			replyMessage, err := rest.AddReply(firstMessage.Id, forthUser.Id, testGroupChannel.Id)
			ResultedWithNoErrorCheck(replyMessage, err)
			time.Sleep(SLEEP_TIME * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("Notification should contain forth, third and second user consecutively", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, thirdUser.Id)
				So(nl.Notifications[0].LatestActors[2], ShouldEqual, secondUser.Id)
			})

			Convey("Notifier count should be 4", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
			})

		})

		Convey("First user should be able to reply it", func() {
			replyMessage, err := rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
			ResultedWithNoErrorCheck(replyMessage, err)
			time.Sleep(SLEEP_TIME * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("Notification should contain first, forth, and third user consecutively", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, forthUser.Id)
				So(nl.Notifications[0].LatestActors[2], ShouldEqual, thirdUser.Id)
			})

			Convey("Notifier count should be 4", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
			})

		})

		Convey("First user should be able to reply it again", func() {
			replyMessage, err := rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
			ResultedWithNoErrorCheck(replyMessage, err)
			time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("Notification should not see first user twice", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, forthUser.Id)
				So(nl.Notifications[0].LatestActors[2], ShouldEqual, thirdUser.Id)
			})

			Convey("Notifier count should be still 4", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
			})

		})

		Convey("Forth user should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(forthUser.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			Convey("Notifier count should be 1", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
			})

			Convey("Notification should contain first user", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
			})

		})

		Convey("As a message owner I must not be notified by my own replies", func() {
			var cm *socialapimodels.ChannelMessage
			var replyMessage *socialapimodels.ChannelMessage

			Convey("I should be able to create channel message", func() {
				messageBody := "notification second message"
				var err error
				cm, err = rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(cm, err)
			})

			Convey("I should be able to reply my message", func() {
				var err error
				replyMessage, err = rest.AddReply(cm.Id, ownerAccount.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should not receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldEqual, 1)
				So(nl.UnreadCount, ShouldEqual, 1)
			})

			Convey("First user should be able to reply it", func() {
				var err error
				replyMessage, err = rest.AddReply(cm.Id, firstUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain two notifications", func() {
					So(nl.UnreadCount, ShouldEqual, 2)
					So(len(nl.Notifications), ShouldEqual, 2)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})

			})

			Convey("First user should not receive notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldEqual, 1)
				So(nl.UnreadCount, ShouldEqual, 1)
			})
		})
		Convey("As a message owner I want to receive like notifications", func() {
			Convey("First user should be able to like it", func() {
				err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
				So(err, ShouldBeNil)
				time.Sleep(SLEEP_TIME * time.Second)
			})
			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should contain three notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 3)
					So(nl.UnreadCount, ShouldEqual, 3)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})
			})
			Convey("First user should be able to relike it", func() {
				err := rest.DeleteInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
				So(err, ShouldBeNil)
				err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
				So(err, ShouldBeNil)
				time.Sleep(SLEEP_TIME * time.Second)
			})
			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should contain three notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 3)
					So(nl.UnreadCount, ShouldEqual, 3)
				})
				Convey("Notifier count should still be 1", func() {
					So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
				})
				Convey("Notification should contain first user as Latest Actors", func() {
					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
				})
			})
			Convey("Second, Third and Forth user should be able to like it", func() {
				err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, secondUser.Id)
				So(err, ShouldBeNil)
				err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, thirdUser.Id)
				So(err, ShouldBeNil)
				err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, forthUser.Id)
				So(err, ShouldBeNil)

				time.Sleep(SLEEP_TIME * time.Second)
			})
			Convey("i Should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should contain three notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 3)
					Convey("Notifier count should be 4", func() {
						So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
					})
					Convey("Notification should contain forth, third and second users consecutively as Latest Actors", func() {
						So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
						So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
						So(nl.Notifications[0].LatestActors[1], ShouldEqual, thirdUser.Id)
						So(nl.Notifications[0].LatestActors[2], ShouldEqual, secondUser.Id)
					})
				})
			})
			Convey("I should not be able to notified by my own like activities", func() {
				err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, ownerAccount.Id)
				So(err, ShouldBeNil)
				time.Sleep(SLEEP_TIME * time.Second)

				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldEqual, 3)
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
			})
		})

		Convey("As a message owner I should be able to glance notifications", func() {
			res, err := rest.GlanceNotifications(ownerAccount.Id)
			ResultedWithNoErrorCheck(res, err)
		})

		Convey("Unread notification count should be 0", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
			ResultedWithNoErrorCheck(nl, err)
			So(nl.UnreadCount, ShouldEqual, 0)

			Convey("All notifications must be set as glanced", func() {
				for _, notification := range nl.Notifications {
					So(notification.Glanced, ShouldEqual, true)
				}
			})
		})

		Convey("As a message owner I should be able to receive new notifications as unread after glance", func() {
			Convey("Third user should be able to reply my first message", func() {
				replyMessage, err := rest.AddReply(firstMessage.Id, thirdUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("Unread count should be 1", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(nl.UnreadCount, ShouldEqual, 1)
				Convey("First notification should be unglanced", func() {
					So(nl.Notifications[0].Glanced, ShouldEqual, false)
				})

				Convey("Second notification should be glanced", func() {
					So(nl.Notifications[1].Glanced, ShouldEqual, true)
				})
			})

		})

		Convey("As a followee I should be able to receive follower notifications when first user follows me", func() {
			Convey("First user should be able to follow me", func() {
				res, err := rest.FollowNotification(firstUser.Id, ownerAccount.Id)
				ResultedWithNoErrorCheck(res, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive follow notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_FOLLOW)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
			})

		})

		Convey("As a followee I should be able to receive a second follower notification after glance", func() {
			Convey("I should be able to glance notifications", func() {
				res, err := rest.GlanceNotifications(ownerAccount.Id)
				ResultedWithNoErrorCheck(res, err)
			})
			Convey("Second user should be able to follow me", func() {
				res, err := rest.FollowNotification(secondUser.Id, ownerAccount.Id)
				ResultedWithNoErrorCheck(res, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})
			Convey("I should be able to receive second follow notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
				Convey("Unread count should be 1", func() {
					So(nl.UnreadCount, ShouldEqual, 1)
				})
			})
		})

		Convey("As a group owner I should be able to receive notification when a user joins my group", func() {
			Convey("First user should be able to join my group", func() {
				channelParticipant, err := rest.AddChannelParticipant(testGroupChannel.Id, firstUser.Id, firstUser.Id)
				ResultedWithNoErrorCheck(channelParticipant, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive join notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(len(nl.Notifications[0].LatestActors), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_JOIN)
			})

			Convey("Second, third and forth user should be able to join my group", func() {
				channelParticipant, err := rest.AddChannelParticipant(testGroupChannel.Id, secondUser.Id, secondUser.Id)
				ResultedWithNoErrorCheck(channelParticipant, err)
				channelParticipant, err = rest.AddChannelParticipant(testGroupChannel.Id, thirdUser.Id, thirdUser.Id)
				ResultedWithNoErrorCheck(channelParticipant, err)
				channelParticipant, err = rest.AddChannelParticipant(testGroupChannel.Id, forthUser.Id, forthUser.Id)
				ResultedWithNoErrorCheck(channelParticipant, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive join notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
				So(nl.Notifications[0].LatestActors[1], ShouldEqual, thirdUser.Id)
				So(nl.Notifications[0].LatestActors[2], ShouldEqual, secondUser.Id)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_JOIN)
			})

			Convey("First user should be able to leave my group", func() {
				channelParticipant, err := rest.DeleteChannelParticipant(testGroupChannel.Id, firstUser.Id, firstUser.Id)
				ResultedWithNoErrorCheck(channelParticipant, err)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive leave notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_LEAVE)
				So(len(nl.Notifications[0].LatestActors), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
			})
		})

		Convey("As a subscriber first and third user should be able to subscribe to my message", func() {
			var cm *socialapimodels.ChannelMessage
			var err error
			Convey("I should be able to create a message", func() {
				messageBody := "notification subscriber message"
				cm, err = rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(cm, err)
			})
			Convey("First user should be able to subscribe to my message", func() {
				response, err := rest.SubscribeMessage(firstUser.Id, cm.Id, testGroupChannel.GroupName)
				ResultedWithNoErrorCheck(response, err)
				time.Now()
			})
			Convey("Second user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(cm.Id, secondUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("First user should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldEqual, cm.Id)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
			})
			Convey("I should be able to unsubscribe from my message", func() {
				response, err := rest.UnsubscribeMessage(ownerAccount.Id, cm.Id, testGroupChannel.GroupName)
				ResultedWithNoErrorCheck(response, err)
			})
			Convey("Third user should be able to subscribe to my message", func() {
				response, err := rest.SubscribeMessage(thirdUser.Id, cm.Id, testGroupChannel.GroupName)
				ResultedWithNoErrorCheck(response, err)
			})
			Convey("First should be able to unsubscribe from my message", func() {
				response, err := rest.UnsubscribeMessage(firstUser.Id, cm.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Third user should be able to subscribe to my message", func() {
				response, err := rest.SubscribeMessage(thirdUser.Id, cm.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Forth user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(cm.Id, forthUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("First user should not be able to receive latest notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, false)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
			})
			Convey("Third user should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(thirdUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldEqual, cm.Id)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				Convey("Notification actor count should be 1", func() {
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
				})
			})
		})

		Convey("As a message owner I should be able to unsubscribe from notifications of my own message", func() {
			var cm *socialapimodels.ChannelMessage
			var err error
			Convey("I should be able to create a message", func() {
				messageBody := "notification subscriber message 2"
				cm, err = rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(cm, err)
			})
			Convey("I should be able to unsubscribe from my message notifications", func() {
				response, err := rest.UnsubscribeMessage(ownerAccount.Id, cm.Id, testGroupChannel.GroupName)
				ResultedWithNoErrorCheck(response, err)
			})
			Convey("First user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(cm.Id, firstUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("I should not be able to receive notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id, cacheEnabled)
				ResultedWithNoErrorCheck(nl, err)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldNotEqual, cm.Id)
			})
			Convey("I should be able to subscribe to my message notifications", func() {
				response, err := rest.SubscribeMessage(ownerAccount.Id, cm.Id, testGroupChannel.GroupName)
				ResultedWithNoErrorCheck(response, err)
			})
			Convey("Second user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(cm.Id, secondUser.Id, testGroupChannel.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

		})
	}

	Convey("while testing notifications without cache", t, func() {
		cacheEnabled = false
		testCases()
	})
}

func ResultedWithNoErrorCheck(result interface{}, err error) {
	So(err, ShouldBeNil)
	So(result, ShouldNotBeNil)
}
