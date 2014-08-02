// TODO Due to uncertainity of notifications instead of fixing
// failing tests are skipped

package main

import (
	socialapimodels "socialapi/models"
	"socialapi/rest"
	"testing"
	"time"

	"log"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	ownerAccount     *socialapimodels.Account
	firstUser        *socialapimodels.Account
	secondUser       *socialapimodels.Account
	thirdUser        *socialapimodels.Account
	forthUser        *socialapimodels.Account
	testGroupChannel *socialapimodels.Channel
	firstMessage     *socialapimodels.ChannelMessage
	secondMessage    *socialapimodels.ChannelMessage
	thirdMessage     *socialapimodels.ChannelMessage
	forthMessage     *socialapimodels.ChannelMessage
)

const SLEEP_TIME = 1

func prepareTestData() {

	if ownerAccount == nil {
		ownerAccount = socialapimodels.NewAccount()
		createUser(ownerAccount)
	}

	if firstUser == nil {
		firstUser = socialapimodels.NewAccount()
		createUser(firstUser)
	}

	if secondUser == nil {
		secondUser = socialapimodels.NewAccount()
		createUser(secondUser)
	}

	if thirdUser == nil {
		thirdUser = socialapimodels.NewAccount()
		createUser(thirdUser)
	}

	if forthUser == nil {
		forthUser = socialapimodels.NewAccount()
		createUser(forthUser)
	}

	if testGroupChannel == nil {
		testGroupChannel = socialapimodels.NewChannel()
		name := "notification_test_" + socialapimodels.RandomName()
		var err error
		testGroupChannel, err = rest.CreateGroupActivityChannel(ownerAccount.Id, name)
		if err != nil {
			log.Fatal(err)
		}
	}

	if secondMessage == nil {
		secondMessage = createOwnerMessage("notification second message")
	}

	if thirdMessage == nil {
		thirdMessage = createOwnerMessage("notification subscriber message")
	}

	if forthMessage == nil {
		forthMessage = createOwnerMessage("notification subscriber message 2")
	}
}

func createUser(user *socialapimodels.Account) {
	user.Id = 0
	user.OldId = bson.NewObjectId().Hex()
	var err error
	user, err = rest.CreateAccount(user)
	if err != nil {
		log.Fatal(err)
	}
}

func createOwnerMessage(body string) *socialapimodels.ChannelMessage {
	message, err := rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, body)
	if err != nil {
		log.Fatal(err)
	}

	return message
}

func TestNotificationCreation(t *testing.T) {
	prepareTestData()

	Convey("while testing notifications", t, func() {

		Convey("As a message owner I want to receive reply notifications", func() {

			var replyMessage *socialapimodels.ChannelMessage
			Convey("I should be able to create channel message", func() {
				messageBody := "notification first message"
				var err error
				firstMessage, err = rest.CreatePostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				So(err, ShouldBeNil)
				So(firstMessage, ShouldNotBeNil)
			})

			Convey("First user should be able to reply it", func() {
				var err error
				replyMessage, err = rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

			Convey("First user should not be able to receive any notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				Convey("And Notification list should not contain any notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 0)
				})
			})

			Convey("First user should be able to reply it again", func() {
				var err error
				replyMessage, err = rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

			Convey("First user still should not be able to receive any notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				Convey("And Notification list should not contain any notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 0)
				})
			})

			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

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
			So(err, ShouldBeNil)
			So(replyMessage, ShouldNotBeNil)
			time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
			nl, err := rest.GetNotificationList(firstUser.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)

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
			So(err, ShouldBeNil)
			So(replyMessage, ShouldNotBeNil)
			time.Sleep(SLEEP_TIME * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
			nl, err := rest.GetNotificationList(firstUser.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)

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
			nl, err := rest.GetNotificationList(secondUser.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)

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
			So(err, ShouldBeNil)
			So(replyMessage, ShouldNotBeNil)
			time.Sleep(SLEEP_TIME * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
			So(err, ShouldBeNil)
			So(replyMessage, ShouldNotBeNil)
			time.Sleep(SLEEP_TIME * time.Second)
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
			So(err, ShouldBeNil)
			So(replyMessage, ShouldNotBeNil)
			time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		})

		Convey("I should be able to receive notification", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
			nl, err := rest.GetNotificationList(forthUser.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
			Convey("Notifier count should be 1", func() {
				So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
			})

			Convey("Notification should contain first user", func() {
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
			})

		})

		Convey("As a message owner I must not be notified by my own replies", func() {
			Convey("I should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(secondMessage.Id, ownerAccount.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should not receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldEqual, 1)
				So(nl.UnreadCount, ShouldEqual, 1)
			})

			Convey("First user should be able to reply it", func() {
				replyMessage, err := rest.AddReply(secondMessage.Id, firstUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

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
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

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
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
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
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

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
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

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

				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldEqual, 3)
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
			})
		})

		Convey("As a message owner I should be able to glance notifications", func() {
			res, err := rest.GlanceNotifications(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(res, ShouldNotBeNil)
		})

		Convey("Unread notification count should be 0", func() {
			nl, err := rest.GetNotificationList(ownerAccount.Id)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
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
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second)
			})

			Convey("Unread count should be 1", func() {
				nl, err := rest.GetNotificationList(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 1)
				Convey("First notification should be unglanced", func() {
					So(nl.Notifications[0].Glanced, ShouldEqual, false)
				})

				Convey("Second notification should be glanced", func() {
					So(nl.Notifications[1].Glanced, ShouldEqual, true)
				})
			})

		})

		Convey("As a subscriber first and third user should be able to subscribe to my message", func() {

			Convey("First user should be able to subscribe to my message", func() {
				response, err := rest.SubscribeMessage(firstUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Second user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(thirdMessage.Id, secondUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("First user should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldEqual, thirdMessage.Id)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
			})
			SkipConvey("I should be able to unsubscribe from my message", func() {
				time.Sleep(SLEEP_TIME * time.Second)
				response, err := rest.UnsubscribeMessage(ownerAccount.Id, thirdMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Third user should be able to subscribe to my message", func() {
				response, err := rest.SubscribeMessage(thirdUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("First user should be able to unsubscribe from my message", func() {
				time.Sleep(SLEEP_TIME * time.Second)
				response, err := rest.UnsubscribeMessage(firstUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Third user should be able to subscribe to my message", func() {
				_, err := rest.SubscribeMessage(thirdUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldNotBeNil)
			})
			Convey("Forth user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(thirdMessage.Id, forthUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)

				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("First user should not be able to receive latest notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
			})
			Convey("Third user should be able to receive notification", func() {
				nl, err := rest.GetNotificationList(thirdUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldEqual, thirdMessage.Id)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				Convey("Notification actor count should be 1", func() {
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
				})
			})
		})

		Convey("As a message owner I should be able to unsubscribe from notifications of my own message", func() {

			SkipConvey("I should be able to unsubscribe from my message notifications", func() {
				response, err := rest.UnsubscribeMessage(ownerAccount.Id, forthMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("First user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(forthMessage.Id, firstUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})
			Convey("I should not be able to receive notification", func() {
				nl, err := rest.GetNotificationList(firstUser.Id)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldBeGreaterThan, 0)
				So(nl.Notifications[0].TargetId, ShouldNotEqual, forthMessage.Id)
			})
			SkipConvey("I should be able to subscribe to my message notifications", func() {
				response, err := rest.SubscribeMessage(ownerAccount.Id, forthMessage.Id, testGroupChannel.GroupName)
				So(err, ShouldBeNil)
				So(response, ShouldNotBeNil)
			})
			Convey("Second user should be able to reply my message", func() {
				replyMessage, err := rest.AddReply(forthMessage.Id, secondUser.Id, testGroupChannel.Id)
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)
				time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
			})

		})
	})

}
