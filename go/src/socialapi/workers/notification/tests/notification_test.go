package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"socialapi/request"
	"socialapi/workers/notification"
	"socialapi/workers/notification/models"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
	"labix.org/v2/mgo/bson"
)

var (
	ownerAccount      *socialapimodels.Account
	firstUser         *socialapimodels.Account
	secondUser        *socialapimodels.Account
	thirdUser         *socialapimodels.Account
	forthUser         *socialapimodels.Account
	testGroupChannel  *socialapimodels.Channel
	testGroupChannel2 *socialapimodels.Channel
	firstMessage      *socialapimodels.ChannelMessage
	secondMessage     *socialapimodels.ChannelMessage
	thirdMessage      *socialapimodels.ChannelMessage
	forthMessage      *socialapimodels.ChannelMessage
	fifthMessage      *socialapimodels.ChannelMessage
)

type testHelper struct {
	t *testing.T
}

func (th *testHelper) prepareTestData() {

	if ownerAccount == nil {
		ownerAccount = socialapimodels.NewAccount()
		th.createUser(ownerAccount)
	}

	if firstUser == nil {
		firstUser = socialapimodels.NewAccount()
		th.createUser(firstUser)
	}

	if secondUser == nil {
		secondUser = socialapimodels.NewAccount()
		th.createUser(secondUser)
	}

	if thirdUser == nil {
		thirdUser = socialapimodels.NewAccount()
		th.createUser(thirdUser)
	}

	if forthUser == nil {
		forthUser = socialapimodels.NewAccount()
		th.createUser(forthUser)
	}

	if testGroupChannel == nil {
		testGroupChannel = socialapimodels.NewChannel()
		name := "notification_test_" + socialapimodels.RandomGroupName()
		testGroupChannel.CreatorId = ownerAccount.Id
		testGroupChannel.Name = name
		err := testGroupChannel.Create()
		if err != nil {
			th.t.Fatal(err)
		}
	}

	if testGroupChannel2 == nil {
		testGroupChannel2 = socialapimodels.NewChannel()
		name := "notification_test_" + socialapimodels.RandomGroupName()
		testGroupChannel2.CreatorId = ownerAccount.Id
		testGroupChannel2.Name = name
		err := testGroupChannel2.Create()
		if err != nil {
			th.t.Fatal(err)
		}
	}

	if firstMessage == nil {
		firstMessage = th.createOwnerMessage("first message it is")
	}

	if secondMessage == nil {
		secondMessage = th.createOwnerMessage("notification second message")
	}

	if thirdMessage == nil {
		thirdMessage = th.createOwnerMessage("notification subscriber message")
	}

	if forthMessage == nil {
		forthMessage = th.createOwnerMessage("notification subscriber message 2")
	}

	if fifthMessage == nil {
		fifthMessage = th.createOwnerMessage("notification subscriber message 2")
	}

	th.addParticipant(ownerAccount, testGroupChannel)
	th.addParticipant(firstUser, testGroupChannel)
	th.addParticipant(secondUser, testGroupChannel)
	th.addParticipant(thirdUser, testGroupChannel)
	th.addParticipant(forthUser, testGroupChannel)
}

func (th *testHelper) addParticipant(account *socialapimodels.Account, channel *socialapimodels.Channel) {
	_, err := channel.AddParticipant(account.Id)
	if err != nil {
		th.t.Error(err)
	}
}

func (th *testHelper) createUser(user *socialapimodels.Account) {
	user.Id = 0
	user.OldId = bson.NewObjectId().Hex()
	user.Nick = user.OldId
	err := user.Create()
	if err != nil {
		th.t.Fatal(err)
	}
}

func (th *testHelper) createOwnerMessage(body string) *socialapimodels.ChannelMessage {
	message, err := createPost(testGroupChannel, ownerAccount, body)
	if err != nil {
		th.t.Fatal(err)
	}

	return message
}

func createPost(groupChannel *socialapimodels.Channel, owner *socialapimodels.Account, body string) (*socialapimodels.ChannelMessage, error) {

	return createPostWithType(groupChannel, owner, body, socialapimodels.ChannelMessage_TYPE_POST)
}

func createPostWithType(groupChannel *socialapimodels.Channel, owner *socialapimodels.Account, body, typeConstant string) (*socialapimodels.ChannelMessage, error) {

	cm := socialapimodels.NewChannelMessage()
	cm.Body = body
	cm.InitialChannelId = groupChannel.Id
	cm.AccountId = owner.Id
	cm.TypeConstant = typeConstant

	err := cm.Create()
	if err != nil {
		return nil, err
	}

	return cm, nil
}

func createReply(groupChannel *socialapimodels.Channel, owner *socialapimodels.Account, parentMessage *socialapimodels.ChannelMessage, body string) (*socialapimodels.MessageReply, error) {
	cm, err := createPost(groupChannel, owner, body)
	So(err, ShouldBeNil)

	reply := socialapimodels.NewMessageReply()
	reply.MessageId = parentMessage.Id
	reply.ReplyId = cm.Id

	err = reply.Create()
	if err != nil {
		return nil, err
	}

	return reply, nil
}

func createInteraction(actor *socialapimodels.Account, message *socialapimodels.ChannelMessage, action string) (*socialapimodels.Interaction, error) {
	i := socialapimodels.NewInteraction()
	i.AccountId = actor.Id
	i.MessageId = message.Id
	i.TypeConstant = action

	err := i.Create()
	if err != nil {
		return nil, err
	}

	return i, nil
}

func deleteInteraction(actor *socialapimodels.Account, message *socialapimodels.ChannelMessage, action string) error {

	i := socialapimodels.NewInteraction()
	i.AccountId = actor.Id
	i.MessageId = message.Id

	return i.Delete()
}

func glance(actor *socialapimodels.Account) error {
	n := models.NewNotification()
	n.AccountId = actor.Id

	return n.Glance()
}

func fetchNotification(accountId int64, contextChannel *socialapimodels.Channel) (*models.NotificationResponse, error) {

	n := models.NewNotification()
	q := &request.Query{}
	q.AccountId = accountId
	q.Limit = 8
	q.GroupChannelId = contextChannel.Id

	return n.List(q)
}

func TestNotificationCreation(t *testing.T) {

	r := runner.New("notification-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	defer modelhelper.Close()

	th := &testHelper{t: t}
	th.prepareTestData()

	controller := notification.New(r.Bongo.Broker.MQ, r.Log)

	createReplyWithGroupHelper := func(owner *socialapimodels.Account, parentMessage *socialapimodels.ChannelMessage, reply string, group *socialapimodels.Channel) {
		replyMessage, err := createReply(group, owner, parentMessage, reply)
		So(err, ShouldBeNil)
		So(replyMessage, ShouldNotBeNil)

		err = controller.CreateReplyNotification(replyMessage)
		So(err, ShouldBeNil)
	}

	createReplyHelper := func(owner *socialapimodels.Account, parentMessage *socialapimodels.ChannelMessage, reply string) {
		createReplyWithGroupHelper(owner, parentMessage, reply, testGroupChannel)
	}

	likeMessage := func(actor *socialapimodels.Account, message *socialapimodels.ChannelMessage) {
		interaction, err := createInteraction(actor, message, socialapimodels.Interaction_TYPE_LIKE)
		So(err, ShouldBeNil)
		So(interaction, ShouldNotBeNil)

		err = controller.CreateInteractionNotification(interaction)
		So(err, ShouldBeNil)
	}

	unlikeMessage := func(actor *socialapimodels.Account, message *socialapimodels.ChannelMessage) {
		err := deleteInteraction(actor, message, socialapimodels.Interaction_TYPE_LIKE)
		So(err, ShouldBeNil)
	}

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

				pm, err := createPostWithType(testGroupChannel, ownerAccount, messageBody, socialapimodels.ChannelMessage_TYPE_PRIVATE_MESSAGE)
				So(err, ShouldBeNil)

				createReplyHelper(secondUser, pm, messageBody)

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(len(nl.Notifications), ShouldEqual, 0)
			})

			Convey("(Basic Reply Notification Test) When first user replies my post I should be able to receive notification", func() {
				createReplyHelper(firstUser, firstMessage, "reply1")
				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(len(nl.Notifications), ShouldEqual, 1)
				notification := nl.Notifications[0]
				So(notification, ShouldNotBeNil)
				So(notification.TargetId, ShouldEqual, firstMessage.Id)
				So(notification.ActorCount, ShouldEqual, 1)
				So(len(notification.LatestActors), ShouldEqual, 1)
				So(notification.LatestActors[0], ShouldEqual, firstUser.Id)

				Convey("First user should not receive any notification for her own activity when she replies twice", func() {
					nl, err := fetchNotification(firstUser.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(len(nl.Notifications), ShouldEqual, 0)

					createReplyHelper(firstUser, firstMessage, "reply2")
					nl, err = fetchNotification(firstUser.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(len(nl.Notifications), ShouldEqual, 0)

					Convey("Unread notification count should still be 1 for my account", func() {
						nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
						So(err, ShouldBeNil)
						So(nl, ShouldNotBeNil)
						So(len(nl.Notifications), ShouldEqual, 1)

						So(nl.UnreadCount, ShouldEqual, 1)
					})
				})

				Convey("When second user replies my post actor count must be two for the latest notification", func() {
					createReplyHelper(secondUser, firstMessage, "reply2")
					nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(len(nl.Notifications), ShouldEqual, 1)
					So(nl.Notifications[0].ActorCount, ShouldEqual, 2)

					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, secondUser.Id)
					So(nl.Notifications[0].LatestActors[1], ShouldEqual, firstUser.Id)
				})
			})

			Convey("Beside the message owner all commenters should be able to receive notification for further replies", func() {

				Convey("When third user replies the message, owner, first and second users receive notification", func() {
					createReplyHelper(thirdUser, firstMessage, "reply3")

					nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)
					So(nl.Notifications, ShouldNotBeEmpty)
					So(nl.Notifications[0].ActorCount, ShouldEqual, 3)

					So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
					So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)
					So(nl.Notifications[0].LatestActors[2], ShouldEqual, firstUser.Id)

					// first user notification fetch
					nl, err = fetchNotification(firstUser.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)

					So(len(nl.Notifications), ShouldEqual, 1)
					So(nl.Notifications[0].ActorCount, ShouldEqual, 2)

					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 2)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
					So(nl.Notifications[0].LatestActors[1], ShouldEqual, secondUser.Id)

					// second user notification fetch
					nl, err = fetchNotification(secondUser.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)

					So(len(nl.Notifications), ShouldEqual, 1)
					// because it must only see the notifiers after him
					So(nl.Notifications[0].ActorCount, ShouldEqual, 1)

					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, thirdUser.Id)
				})

			})

			Convey("As a message owner I should not be notified for my own replies", func() {
				createReplyHelper(ownerAccount, secondMessage, "reply1")

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldEqual, 1)
				So(nl.UnreadCount, ShouldEqual, 1)
			})
		})

		Convey("As a message owner I want to receive like notifications", func() {
			Convey("I should be able to receive notification when a user likes my post", func() {
				likeMessage(firstUser, firstMessage)

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldEqual, 2)
				So(nl.UnreadCount, ShouldEqual, 2)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_LIKE)
				So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)

				// other users like the message
				likeMessage(secondUser, firstMessage)
				likeMessage(thirdUser, firstMessage)
				likeMessage(forthUser, firstMessage)

				nl, err = fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)

				So(len(nl.Notifications), ShouldEqual, 2)
				So(nl.UnreadCount, ShouldEqual, 2)
				So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_LIKE)
				So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
				So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
				So(nl.Notifications[0].LatestActors[0], ShouldEqual, forthUser.Id)

				Convey("In case of a relike, I should not receive a new notification item", func() {
					unlikeMessage(firstUser, firstMessage)
					likeMessage(firstUser, firstMessage)

					nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
					So(err, ShouldBeNil)
					So(nl, ShouldNotBeNil)

					So(len(nl.Notifications), ShouldEqual, 2)
					So(nl.UnreadCount, ShouldEqual, 2)
					So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_LIKE)
					So(nl.Notifications[0].ActorCount, ShouldEqual, 4)
					So(len(nl.Notifications[0].LatestActors), ShouldEqual, 3)
					So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)
				})
			})

		})

		Convey("As a message owner I should be able to glance notifications", func() {
			err := glance(ownerAccount)
			So(err, ShouldBeNil)

			nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)
			So(nl.UnreadCount, ShouldEqual, 0)

			for _, notification := range nl.Notifications {
				So(notification.Glanced, ShouldEqual, true)
			}

			Convey("As a message owner I should be able to receive new notifications as unread after glance", func() {
				createReplyHelper(thirdUser, firstMessage, "anotherreply")

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 1)
				So(len(nl.Notifications), ShouldEqual, 2)
				So(nl.Notifications[0].Glanced, ShouldEqual, false)

				So(nl.Notifications[1].Glanced, ShouldEqual, true)

			})
		})

		Convey("I should be able to receive notifications when a user mentions me in their post", func() {
			body := fmt.Sprintf("@%s hello", ownerAccount.OldId)
			cm, err := createPost(testGroupChannel, firstUser, body)
			So(err, ShouldBeNil)
			So(cm, ShouldNotBeNil)

			err = controller.HandleMessage(cm)
			So(err, ShouldBeNil)

			nl, err := fetchNotification(ownerAccount.Id, testGroupChannel)
			So(err, ShouldBeNil)
			So(nl, ShouldNotBeNil)

			So(nl.Notifications, ShouldNotBeEmpty)
			So(nl.Notifications[0].TypeConstant, ShouldEqual, models.NotificationContent_TYPE_MENTION)
			So(nl.Notifications[0].ActorCount, ShouldEqual, 1)
			So(len(nl.Notifications[0].LatestActors), ShouldEqual, 1)
			So(nl.Notifications[0].LatestActors[0], ShouldEqual, firstUser.Id)

		})

		// TODO complete this test
		SkipConvey("I should be able to receive to receive notification when a user mentions me in their comment", func() {

		})

		Convey("I should be able to fetch notifications from different group channels", func() {
			cm, err := createPost(testGroupChannel2, ownerAccount, "hello")
			So(err, ShouldBeNil)
			So(cm, ShouldNotBeNil)

			Convey("I should not receive any notifications when I am not a participant of the group channel", func() {
				// checking reply notification
				createReplyWithGroupHelper(firstUser, cm, "anotherreply", testGroupChannel2)

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel2)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 0)
				So(len(nl.Notifications), ShouldEqual, 0)

				// checking like notification
				likeMessage(firstUser, cm)
				nl, err = fetchNotification(ownerAccount.Id, testGroupChannel2)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 0)
				So(len(nl.Notifications), ShouldEqual, 0)

				// checking mention notification
				body := fmt.Sprintf("@%s hello", ownerAccount.OldId)
				cm, err := createPost(testGroupChannel2, firstUser, body)
				So(err, ShouldBeNil)
				So(cm, ShouldNotBeNil)

				nl, err = fetchNotification(ownerAccount.Id, testGroupChannel2)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 0)
				So(len(nl.Notifications), ShouldEqual, 0)
			})

			Convey("I should receive reply notification of my post only when I am a participant of the channel", func() {

				th.addParticipant(ownerAccount, testGroupChannel2)

				createReplyWithGroupHelper(firstUser, cm, "anotherreply2", testGroupChannel2)

				nl, err := fetchNotification(ownerAccount.Id, testGroupChannel2)
				So(err, ShouldBeNil)
				So(nl, ShouldNotBeNil)
				So(nl.UnreadCount, ShouldEqual, 1)
				So(len(nl.Notifications), ShouldEqual, 1)
			})
		})

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
