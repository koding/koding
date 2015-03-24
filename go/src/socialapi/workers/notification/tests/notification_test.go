package main

import (
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/request"
	"socialapi/workers/common/runner"
	"socialapi/workers/notification"
	"socialapi/workers/notification/models"
	"testing"

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
	fifthMessage     *socialapimodels.ChannelMessage
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
		testGroupChannel.CreatorId = ownerAccount.Id
		testGroupChannel.Name = name
		err := testGroupChannel.Create()
		if err != nil {
			log.Fatal(err)
		}
	}

	if firstMessage == nil {
		firstMessage = createOwnerMessage("first message it is")
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

	if fifthMessage == nil {
		fifthMessage = createOwnerMessage("notification subscriber message 2")
	}
}

func createUser(user *socialapimodels.Account) {
	user.Id = 0
	user.OldId = bson.NewObjectId().Hex()
	user.Nick = user.OldId
	err := user.Create()
	if err != nil {
		log.Fatal(err)
	}
}

func createOwnerMessage(body string) *socialapimodels.ChannelMessage {
	message, err := createPost(testGroupChannel.Id, ownerAccount.Id, body)
	if err != nil {
		log.Fatal(err)
	}

	return message
}

func createPost(groupChannelId, ownerId int64, body string) (*socialapimodels.ChannelMessage, error) {

	return createPostWithType(groupChannelId, ownerId, body, socialapimodels.ChannelMessage_TYPE_POST)
}

func createPostWithType(groupChannelId, ownerId int64, body string, typeConstant string) (*socialapimodels.ChannelMessage, error) {

	cm := socialapimodels.NewChannelMessage()
	cm.Body = body
	cm.InitialChannelId = groupChannelId
	cm.AccountId = ownerId
	cm.TypeConstant = typeConstant

	err := cm.Create()
	if err != nil {
		return nil, err
	}

	return cm, nil
}

func createReply(groupChannelId, ownerId, messageId int64, body string) (*socialapimodels.MessageReply, error) {
	cm, err := createPost(groupChannelId, ownerId, body)
	So(err, ShouldBeNil)

	reply := socialapimodels.NewMessageReply()
	reply.MessageId = messageId
	reply.ReplyId = cm.Id

	err = reply.Create()
	if err != nil {
		return nil, err
	}

	return reply, nil
}

func fetchNotification(accountId int64) (*models.NotificationResponse, error) {

	n := models.NewNotification()
	q := &request.Query{}
	q.AccountId = accountId
	q.Limit = 8

	return n.List(q)
}

func TestNotificationCreation(t *testing.T) {

	r := runner.New("notification-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	prepareTestData()

	controller := notification.New(r.Bongo.Broker.MQ, r.Log)

	Convey("while testing notifications", t, func() {

		Convey("As a message owner I want to receive reply notifications", func() {

			Convey("I should receive error when message reply does not exist", func() {
				mr := socialapimodels.NewMessageReply()
				mr.ReplyId = 123123123
				err := controller.CreateReplyNotification(mr)
				So(err, ShouldNotBeNil)
			})

			Convey("I should only receive notification for my messages with post type", func() {
				messageBody := "notification first message"

				pm, err := createPostWithType(testGroupChannel.Id, ownerAccount.Id, messageBody, socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE)
				So(err, ShouldBeNil)

				reply, err := createReply(testGroupChannel.Id, secondUser.Id, pm.Id, messageBody)
				So(err, ShouldBeNil)

				err = controller.CreateReplyNotification(reply)
				So(err, ShouldBeNil)

				nl, err := fetchNotification(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(len(nl.Notifications), ShouldEqual, 0)
			})

			Convey("When first user replies my post I should be able to receive notification", func() {
				replyMessage, err := createReply(testGroupChannel.Id, firstUser.Id, firstMessage.Id, "reply1")
				So(err, ShouldBeNil)
				So(replyMessage, ShouldNotBeNil)

				err = controller.CreateReplyNotification(replyMessage)
				So(err, ShouldBeNil)

				nl, err := fetchNotification(ownerAccount.Id)
				So(err, ShouldBeNil)
				So(len(nl.Notifications), ShouldEqual, 1)
				notification := nl.Notifications[0]
				So(notification, ShouldNotBeNil)
				So(notification.TargetId, ShouldEqual, firstMessage.Id)
				So(notification.ActorCount, ShouldEqual, 1)
				So(len(notification.LatestActors), ShouldEqual, 1)
				So(notification.LatestActors[0], ShouldEqual, firstUser.Id)

				Convey("First user should not receive any notification for her own activity when she replies twice", func() {
					nl, err := fetchNotification(firstUser.Id)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(len(nl.Notifications), ShouldEqual, 0)

					replyMessage, err = createReply(testGroupChannel.Id, firstUser.Id, firstMessage.Id, "reply2")
					nl, err = fetchNotification(firstUser.Id)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(len(nl.Notifications), ShouldEqual, 0)

					Convey("I should not receive any new notification for second reply from first user", func() {
						nl, err := fetchNotification(ownerAccount.Id)
						So(err, ShouldBeNil)
						So(nl, ShouldNotBeNil)
						So(len(nl.Notifications), ShouldEqual, 1)

						So(nl.UnreadCount, ShouldEqual, 1)
					})
				})
			})

		})

		//Convey("Second user should be able to reply it", func() {
		//    replyMessage, err := rest.AddReply(firstMessage.Id, secondUser.Id, testGroupChannel.Id)
		//    So(err, ShouldBeNil)
		//    So(replyMessage, ShouldNotBeNil)
		//    time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		//})

		//Convey("I should be able to receive a new notification for the same message", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("And Notification list should contain one notification", func() {
		//        So(len(nl.Notifications), ShouldEqual, 1)
		//    })
		//    Convey("Notifier count should be 2", func() {
		//        So(len(nl.Notifications), ShouldEqual, 1)
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 2)
		//    })

		//    Convey("Notification should contain second and first user consecutively", func() {
		//        So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, firstUser.Id)
		//    })

		//})

		//Convey("First user should be able to receive notification as the previous commenter", func() {
		//    nl, err := rest.GetNotificationList(firstUser.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)

		//    Convey("And Notification list should contain one notification", func() {
		//        So(len(nl.Notifications), ShouldEqual, 1)
		//        Convey("Notifier count should be 1", func() {
		//            So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//        })
		//        Convey("Notification should contain second user", func() {
		//            So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//            So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
		//        })
		//    })

		//})

		//Convey("Third user should be able to reply it", func() {
		//    replyMessage, err := rest.AddReply(firstMessage.Id, thirdUser.Id, testGroupChannel.Id)
		//    So(err, ShouldBeNil)
		//    So(replyMessage, ShouldNotBeNil)
		//    time.Sleep(SLEEP_TIME * time.Second)
		//})

		//Convey("I should be able to receive notification as the message owner", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("Notifier count should be 3", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 3)
		//    })

		//    Convey("Notification should contain third, second and first user consecutively", func() {
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)
		//        So(nl.Notifications[0].LatestActors[2], ShouldEqual, firstUser.Id)
		//    })
		//})

		//Convey("First user should be able to receive notification after third user's post", func() {
		//    nl, err := rest.GetNotificationList(firstUser.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)

		//    Convey("And Notification list should contain one notification", func() {
		//        So(len(nl.Notifications), ShouldEqual, 1)
		//    })
		//    Convey("Notifier count should be 2", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 2)
		//    })

		//    Convey("Notification should contain third and second user consecutively", func() {
		//        So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)
		//    })

		//})

		//Convey("Second user should be able to receive notification as the previous commenter", func() {
		//    nl, err := rest.GetNotificationList(secondUser.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)

		//    Convey("And Notification list should contain one notification", func() {
		//        So(len(nl.Notifications), ShouldEqual, 1)
		//    })
		//    // because it must only see the notifiers after him
		//    Convey("Notifier count should be 1", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//    })

		//    Convey("Notification should contain third user only", func() {
		//        So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
		//    })

		//})

		//Convey("Forth user should be able to reply it", func() {
		//    replyMessage, err := rest.AddReply(firstMessage.Id, forthUser.Id, testGroupChannel.Id)
		//    So(err, ShouldBeNil)
		//    So(replyMessage, ShouldNotBeNil)
		//    time.Sleep(SLEEP_TIME * time.Second)
		//})

		//Convey("I should be able to receive notification as the message owner after forth users reply", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("Notification should contain forth, third and second user consecutively, first user should not be included", func() {
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, thirdUser.Id)
		//        So(nl.Notifications[0].LatestActors[2], ShouldEqual, secondUser.Id)
		//    })

		//    Convey("Notifier count should be 4", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//    })

		//})

		//Convey("First user should be able to reply it", func() {
		//    replyMessage, err := rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
		//    So(err, ShouldBeNil)
		//    So(replyMessage, ShouldNotBeNil)
		//    time.Sleep(SLEEP_TIME * time.Second)
		//})

		//Convey("I should be able to receive notification as the message owner after first user's reply", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("Notification should contain first, forth, and third user consecutively (first user is relisted)", func() {
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, forthUser.Id)
		//        So(nl.Notifications[0].LatestActors[2], ShouldEqual, thirdUser.Id)
		//    })

		//    Convey("Notifier count should be 4", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//    })

		//})

		//Convey("First user should be able to reply it again (owner of consecutive comments)", func() {
		//    replyMessage, err := rest.AddReply(firstMessage.Id, firstUser.Id, testGroupChannel.Id)
		//    So(err, ShouldBeNil)
		//    So(replyMessage, ShouldNotBeNil)
		//    time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		//})

		//Convey("I should be able to receive notification as the message owner", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("Notification should not see first user twice", func() {
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//        So(nl.Notifications[0].LatestActors[1], ShouldEqual, forthUser.Id)
		//        So(nl.Notifications[0].LatestActors[2], ShouldEqual, thirdUser.Id)
		//    })

		//    Convey("Notifier count should be still 4", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//    })

		//})

		//Convey("Forth user should be able to receive notification as the previous commenter", func() {
		//    nl, err := rest.GetNotificationList(forthUser.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    Convey("Notifier count should be 1", func() {
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//    })

		//    Convey("Notification should contain only first user since she is the last commenter", func() {
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//    })

		//})

		//Convey("As a message owner I must not be notified by my own replies", func() {
		//    Convey("I should be able to reply my message", func() {
		//        replyMessage, err := rest.AddReply(secondMessage.Id, ownerAccount.Id, testGroupChannel.Id)
		//        So(err, ShouldBeNil)
		//        So(replyMessage, ShouldNotBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })

		//    Convey("I should not receive notification for my own message", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        So(len(nl.Notifications), ShouldEqual, 1)
		//        So(nl.UnreadCount, ShouldEqual, 1)
		//    })

		//    Convey("First user should be able to reply it", func() {
		//        replyMessage, err := rest.AddReply(secondMessage.Id, firstUser.Id, testGroupChannel.Id)
		//        So(err, ShouldBeNil)
		//        So(replyMessage, ShouldNotBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })

		//    Convey("I should be able to receive comment notification", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        Convey("And Notification list should contain two notifications for my two posts", func() {
		//            So(nl.UnreadCount, ShouldEqual, 2)
		//            So(len(nl.Notifications), ShouldEqual, 2)
		//            Convey("Notifier count should be 1", func() {
		//                So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//            })
		//            Convey("Notification should contain first user as actor", func() {
		//                So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//                So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//            })
		//        })

		//    })

		//    Convey("First user should not receive notification", func() {
		//        nl, err := rest.GetNotificationList(firstUser.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        So(len(nl.Notifications), ShouldEqual, 1)
		//        So(nl.UnreadCount, ShouldEqual, 1)
		//    })

		//})
		//Convey("As a message owner I want to receive like notifications", func() {
		//    Convey("First user should be able to like it", func() {
		//        _, err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
		//        So(err, ShouldBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })
		//    Convey("I should be able to receive notification for my own post", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)
		//        Convey("And Notification list should contain three notifications (like, 2 * reply)", func() {
		//            So(len(nl.Notifications), ShouldEqual, 3)
		//            So(nl.UnreadCount, ShouldEqual, 3)
		//            Convey("Notifier count should be 1", func() {
		//                So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//            })
		//            Convey("Like notification should contain first user as actor", func() {
		//                So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//                So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//            })
		//        })
		//    })
		//    Convey("First user should be able to relike it", func() {
		//        err := rest.DeleteInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
		//        So(err, ShouldBeNil)
		//        _, err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
		//        So(err, ShouldBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })
		//    Convey("I should be able to receive notification (latest like notification should be updated)", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        Convey("And Notification list should contain three notifications (like, 2 * reply)", func() {
		//            So(len(nl.Notifications), ShouldEqual, 3)
		//            So(nl.UnreadCount, ShouldEqual, 3)
		//        })
		//        Convey("Notifier count should still be 1", func() {
		//            So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//        })
		//        Convey("Notification should contain first user as actor", func() {
		//            So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//            So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//        })
		//    })
		//    Convey("Second, Third and Forth user should be able to like it", func() {
		//        _, err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, secondUser.Id)
		//        So(err, ShouldBeNil)
		//        _, err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, thirdUser.Id)
		//        So(err, ShouldBeNil)
		//        _, err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, forthUser.Id)
		//        So(err, ShouldBeNil)

		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })
		//    Convey("I should be able to receive like notification", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        Convey("And Notification list should contain three notifications (like, 2 * reply)", func() {
		//            So(len(nl.Notifications), ShouldEqual, 3)
		//            Convey("Notifier count should be 4", func() {
		//                So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//            })
		//            Convey("Notification should contain forth, third and second users consecutively as actors", func() {
		//                So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
		//                So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
		//                So(nl.Notifications[0].LatestActors[1], ShouldEqual, thirdUser.Id)
		//                So(nl.Notifications[0].LatestActors[2], ShouldEqual, secondUser.Id)
		//            })
		//        })
		//    })
		//    Convey("I should not be notified when I liked my own post", func() {
		//        _, err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)

		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        So(len(nl.Notifications), ShouldEqual, 3)
		//        So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//        So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
		//        So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
		//    })
		//    // test behavior when first user relikes the post
		//    Convey("First user should be able to relike it", func() {
		//        err := rest.DeleteInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
		//        So(err, ShouldBeNil)
		//        _, err = rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
		//        So(err, ShouldBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })
		//    Convey("I should be able to receive like notification", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        Convey("And Notification list should contain three notifications (like, 2 * reply)", func() {
		//            So(len(nl.Notifications), ShouldEqual, 3)
		//            Convey("Notifier count should be 4", func() {
		//                So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
		//            })
		//            Convey("Notification should contain first, forth, and third users consecutively as actors", func() {
		//                So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
		//                So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//                So(nl.Notifications[0].LatestActors[1], ShouldEqual, forthUser.Id)
		//                So(nl.Notifications[0].LatestActors[2], ShouldEqual, thirdUser.Id)
		//            })
		//        })
		//    })
		//})

		//Convey("As a message owner I should be able to glance notifications", func() {
		//    res, err := rest.GlanceNotifications(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(res, ShouldNotBeNil)
		//})

		//Convey("Unread notification count should be 0 after glance", func() {
		//    nl, err := rest.GetNotificationList(ownerAccount.Id)
		//    So(err, ShouldBeNil)
		//    So(nl, ShouldNotBeNil)
		//    So(nl.UnreadCount, ShouldEqual, 0)

		//    Convey("All notifications must be set as glanced", func() {
		//        for _, notification := range nl.Notifications {
		//            So(notification.Glanced, ShouldEqual, true)
		//        }
		//    })
		//})

		//Convey("As a message owner I should be able to receive new notifications as unread after glance", func() {
		//    Convey("Third user should be able to reply my first message", func() {
		//        replyMessage, err := rest.AddReply(firstMessage.Id, thirdUser.Id, testGroupChannel.Id)
		//        So(err, ShouldBeNil)
		//        So(replyMessage, ShouldNotBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })

		//    Convey("Unread count should be 1", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)
		//        So(nl.UnreadCount, ShouldEqual, 1)
		//        Convey("First notification should be unglanced", func() {
		//            So(nl.Notifications[0].Glanced, ShouldEqual, false)
		//        })

		//        Convey("Second notification should be glanced", func() {
		//            So(nl.Notifications[1].Glanced, ShouldEqual, true)
		//        })
		//    })

		//})

		//Convey("I should be able to receive notifications when a user mentions me in her post", func() {
		//    var cm *socialapimodels.ChannelMessage
		//    Convey("First user should be able to mention me in her post", func() {
		//        body := fmt.Sprintf("@%s hello", ownerAccount.OldId)
		//        var err error
		//        cm, err = rest.CreatePostWithBody(testGroupChannel.Id, firstUser.Id, body)
		//        So(err, ShouldBeNil)
		//        So(cm, ShouldNotBeNil)

		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })

		//    Convey("I should be able to receive mention notification", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)

		//        Convey("And Notification list should contain four notifications (mention, like, 2 * reply)", func() {
		//            So(len(nl.Notifications), ShouldEqual, 4)
		//            So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_MENTION)
		//            Convey("Notifier count should be 1", func() {
		//                So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
		//            })
		//            Convey("Notification should contain first user as actors", func() {
		//                So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		//                So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
		//            })
		//        })
		//    })

		//})

		//Convey("I should not be able to receive notifications of a deleted message", func() {
		//    Convey("First user should be able to reply my fifth message", func() {
		//        replyMessage, err := rest.AddReply(fifthMessage.Id, firstUser.Id, testGroupChannel.Id)
		//        So(err, ShouldBeNil)
		//        So(replyMessage, ShouldNotBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		//    })

		//    Convey("Second user should be able to like it", func() {
		//        _, err := rest.AddInteraction(socialapimodels.Interaction_TYPE_LIKE, fifthMessage.Id, secondUser.Id)
		//        So(err, ShouldBeNil)
		//        time.Sleep(SLEEP_TIME * time.Second)
		//    })

		//    Convey("And Notification list should contain six notifications (like, reply, mention, like, 2 * reply)", func() {
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)
		//        So(len(nl.Notifications), ShouldEqual, 6)

		//    })

		//    Convey("I should be able to delete fifth message", func() {
		//        err := rest.DeletePost(fifthMessage.Id, ownerAccount.Id, testGroupChannel.GroupName)
		//        So(err, ShouldBeNil)
		//    })

		//    Convey("Like and comment notifications should be deleted from my notification list", func() {
		//        err := rest.DeletePost(fifthMessage.Id, ownerAccount.Id, testGroupChannel.GroupName)
		//        nl, err := rest.GetNotificationList(ownerAccount.Id)
		//        So(err, ShouldBeNil)
		//        So(nl, ShouldNotBeNil)
		//        So(len(nl.Notifications), ShouldEqual, 4)
		//    })
		//})

		// Convey("As a subscriber first and third user should be able to subscribe to my message", func() {

		// 	Convey("First user should be able to subscribe to my message", func() {
		// 		response, err := rest.SubscribeMessage(firstUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("Second user should be able to reply my message", func() {
		// 		replyMessage, err := rest.AddReply(thirdMessage.Id, secondUser.Id, testGroupChannel.Id)
		// 		So(err, ShouldBeNil)
		// 		So(replyMessage, ShouldNotBeNil)
		// 		time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		// 	})
		// 	Convey("First user should be able to receive notification", func() {
		// 		nl, err := rest.GetNotificationList(firstUser.Id)
		// 		So(err, ShouldBeNil)
		// 		So(nl, ShouldNotBeNil)

		// 		So(len(nl.Notifications), ShouldBeGreaterThan, 0)
		// 		So(nl.Notifications[0].TargetId, ShouldEqual, thirdMessage.Id)
		// 		So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		// 		So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
		// 	})
		// 	SkipConvey("I should be able to unsubscribe from my message", func() {
		// 		time.Sleep(SLEEP_TIME * time.Second)
		// 		response, err := rest.UnsubscribeMessage(ownerAccount.Id, thirdMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("Third user should be able to subscribe to my message", func() {
		// 		response, err := rest.SubscribeMessage(thirdUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("First user should be able to unsubscribe from my message", func() {
		// 		time.Sleep(SLEEP_TIME * time.Second)
		// 		response, err := rest.UnsubscribeMessage(firstUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("Third user should be able to subscribe to my message", func() {
		// 		_, err := rest.SubscribeMessage(thirdUser.Id, thirdMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldNotBeNil)
		// 	})
		// 	Convey("Forth user should be able to reply my message", func() {
		// 		replyMessage, err := rest.AddReply(thirdMessage.Id, forthUser.Id, testGroupChannel.Id)
		// 		So(err, ShouldBeNil)
		// 		So(replyMessage, ShouldNotBeNil)

		// 		time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		// 	})
		// 	Convey("First user should not be able to receive latest notification", func() {
		// 		nl, err := rest.GetNotificationList(firstUser.Id)
		// 		So(err, ShouldBeNil)
		// 		So(nl, ShouldNotBeNil)

		// 		So(len(nl.Notifications), ShouldBeGreaterThan, 0)
		// 		So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		// 		So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
		// 	})
		// 	Convey("Third user should be able to receive notification", func() {
		// 		nl, err := rest.GetNotificationList(thirdUser.Id)
		// 		So(err, ShouldBeNil)
		// 		So(nl, ShouldNotBeNil)

		// 		So(len(nl.Notifications), ShouldBeGreaterThan, 0)
		// 		So(nl.Notifications[0].TargetId, ShouldEqual, thirdMessage.Id)
		// 		So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
		// 		Convey("Notification actor count should be 1", func() {
		// 			So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)
		// 		})
		// 	})
		// })

		// Convey("As a message owner I should be able to unsubscribe from notifications of my own message", func() {

		// 	SkipConvey("I should be able to unsubscribe from my message notifications", func() {
		// 		response, err := rest.UnsubscribeMessage(ownerAccount.Id, forthMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("First user should be able to reply my message", func() {
		// 		replyMessage, err := rest.AddReply(forthMessage.Id, firstUser.Id, testGroupChannel.Id)
		// 		So(err, ShouldBeNil)
		// 		So(replyMessage, ShouldNotBeNil)
		// 		time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		// 	})
		// 	Convey("I should not be able to receive notification", func() {
		// 		nl, err := rest.GetNotificationList(firstUser.Id)
		// 		So(err, ShouldBeNil)
		// 		So(nl, ShouldNotBeNil)

		// 		So(len(nl.Notifications), ShouldBeGreaterThan, 0)
		// 		So(nl.Notifications[0].TargetId, ShouldNotEqual, forthMessage.Id)
		// 	})
		// 	SkipConvey("I should be able to subscribe to my message notifications", func() {
		// 		response, err := rest.SubscribeMessage(ownerAccount.Id, forthMessage.Id, testGroupChannel.GroupName)
		// 		So(err, ShouldBeNil)
		// 		So(response, ShouldNotBeNil)
		// 	})
		// 	Convey("Second user should be able to reply my message", func() {
		// 		replyMessage, err := rest.AddReply(forthMessage.Id, secondUser.Id, testGroupChannel.Id)
		// 		So(err, ShouldBeNil)
		// 		So(replyMessage, ShouldNotBeNil)
		// 		time.Sleep(SLEEP_TIME * time.Second) // waiting for async message
		// 	})

		// })
	})

}
