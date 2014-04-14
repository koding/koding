package main

import (
	"encoding/json"
	"fmt"
	. "github.com/smartystreets/goconvey/convey"
	"socialapi/models"
	"testing"
	"time"
)

func TestNotificationCreation(t *testing.T) {
	ownerAccount := models.NewAccount()
	firstUser := models.NewAccount()
	secondUser := models.NewAccount()
	thirdUser := models.NewAccount()
	forthUser := models.NewAccount()
	testGroupChannel := models.NewChannel()
	var firstMessage *models.ChannelMessage

	Convey("while testing reply notifications", t, func() {
		Convey("First create users and required channel", func() {
			Convey("We should be able to create accounts", func() {
				var err error

				ownerAccount.OldId = AccountOldId.Hex()
				ownerAccount, err = createAccount(ownerAccount)
				ResultedWithNoErrorCheck(ownerAccount, err)

				firstUser.OldId = AccountOldId2.Hex()
				firstUser, err = createAccount(firstUser)
				ResultedWithNoErrorCheck(firstUser, err)

				secondUser.OldId = AccountOldId3.Hex()
				secondUser, err = createAccount(secondUser)
				ResultedWithNoErrorCheck(secondUser, err)

				thirdUser.OldId = AccountOldId4.Hex()
				thirdUser, err = createAccount(thirdUser)
				ResultedWithNoErrorCheck(thirdUser, err)

				forthUser.OldId = AccountOldId5.Hex()
				forthUser, err = createAccount(forthUser)
				ResultedWithNoErrorCheck(forthUser, err)
			})

			Convey("We should be able to create notification_test group channel", func() {
				var err error
				testGroupChannel, err = createChannelByGroupNameAndType(ownerAccount.Id, "notification_test", models.Channel_TYPE_GROUP)
				ResultedWithNoErrorCheck(testGroupChannel, err)
			})
		})
		Convey("As a message owner I want to receive reply notifications", func() {

			var replyMessage *models.ChannelMessage
			Convey("I should be able to create channel message", func() {
				messageBody := "notification first message"
				var err error
				firstMessage, err = createPostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(firstMessage, err)
			})

			Convey("First user should be able to reply it", func() {
				var err error
				replyMessage, err = addReply(firstMessage.Id, firstUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(5 * time.Second) // waiting for async message
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})

				Convey("And Unread notification count should be 1 ", func() {
					So(nl.UnreadCount, ShouldEqual, 1)
				})

			})

			Convey("Second user should be able to reply it", func() {
				replyMessage, err := addReply(firstMessage.Id, secondUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
				})
				Convey("Notifier count should be 2", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 2)
				})

				Convey("Notification should contain second and first user consecutively", func() {
					So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 2)
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, secondUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, firstUser.Id)
				})

			})

			Convey("First user should be able to receive notification", func() {
				nl, err := getNotificationList(firstUser.Id)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
				})
				Convey("Notifier count should be 1", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
				})

				Convey("Notification should contain second user", func() {
					So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 1)
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, secondUser.Id)
				})

			})

			Convey("Third user should be able to reply it", func() {
				replyMessage, err := addReply(firstMessage.Id, thirdUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("Notifier count should be 3", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 3)
				})

				Convey("Notification should contain third, second and first user consecutively", func() {
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, thirdUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, secondUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[2], ShouldEqual, firstUser.Id)
				})
			})

			Convey("First user should be able to receive notification", func() {
				nl, err := getNotificationList(firstUser.Id)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
				})
				Convey("Notifier count should be 2", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 2)
				})

				Convey("Notification should contain third and second user consecutively", func() {
					So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 2)
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, thirdUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, secondUser.Id)
				})

			})

			Convey("Second user should be able to receive notification", func() {
				nl, err := getNotificationList(secondUser.Id)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					So(len(nl.Notifications), ShouldEqual, 1)
				})
				// because it must only see the notifiers after him
				Convey("Notifier count should be 1", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
				})

				Convey("Notification should contain third user only", func() {
					So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 1)
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, thirdUser.Id)
				})

			})

			Convey("Forth user should be able to reply it", func() {
				replyMessage, err := addReply(firstMessage.Id, forthUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("Notification should contain forth, third and second user consecutively", func() {
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, forthUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, thirdUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[2], ShouldEqual, secondUser.Id)
				})

				Convey("Notifier count should be 4", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 4)
				})

			})

			Convey("First user should be able to reply it", func() {
				replyMessage, err := addReply(firstMessage.Id, firstUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("Notification should contain first, forth, and third user consecutively", func() {
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, forthUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[2], ShouldEqual, thirdUser.Id)
				})

				Convey("Notifier count should be 4", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 4)
				})

			})

			Convey("First user should be able to reply it again", func() {
				replyMessage, err := addReply(firstMessage.Id, firstUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("Notification should not see first user twice", func() {
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[1], ShouldEqual, forthUser.Id)
					So(nl.Notifications[0].Actors.LatestActors[2], ShouldEqual, thirdUser.Id)
				})

				Convey("Notifier count should be still 4", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 4)
				})

			})

			Convey("Forth user should be able to receive notification", func() {
				nl, err := getNotificationList(forthUser.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("Notifier count should be 1", func() {
					So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
				})

				Convey("Notification should contain first user", func() {
					So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
				})

			})

		})

		Convey("As a message owner I must not be notified by my own replies", func() {
			var cm *models.ChannelMessage
			var replyMessage *models.ChannelMessage

			Convey("I should be able to create channel message", func() {
				messageBody := "notification second message"
				var err error
				cm, err = createPostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(cm, err)
			})

			Convey("I should be able to reply my message", func() {
				var err error
				replyMessage, err = addReply(cm.Id, ownerAccount.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(5 * time.Second)
			})

			Convey("I should not receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				So(len(nl.Notifications), ShouldEqual, 1)
			})

			Convey("Another user should be able to reply it", func() {
				var err error
				replyMessage, err = addReply(cm.Id, firstUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
				time.Sleep(5 * time.Second)
			})

			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain two notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 2)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})

			})

		})

		Convey("As a message owner I want to receive like notifications", func() {
			Convey("First user should be able to like it", func() {
				err := addInteraction(models.Interaction_TYPE_LIKE, firstMessage.Id, firstUser.Id)
				So(err, ShouldBeNil)
				time.Sleep(5 * time.Second)
			})
			Convey("I should be able to receive notification", func() {
				nl, err := getNotificationList(ownerAccount.Id)
				ResultedWithNoErrorCheck(nl, err)
				Convey("And Notification list should contain three notifications", func() {
					So(len(nl.Notifications), ShouldEqual, 3)
					Convey("Notifier count should be 1", func() {
						So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
					})
					Convey("Notification should contain first user as Latest Actors", func() {
						So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, 1)
						So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					})
				})
			})
		})

	})

}

func TestLikeNotificationCreation(t *testing.T) {

}

func ResultedWithNoErrorCheck(result interface{}, err error) {
	So(err, ShouldBeNil)
	So(result, ShouldNotBeNil)
}

func getNotificationList(accountId int64) (*models.NotificationResponse, error) {
	url := fmt.Sprintf("/notification/%d", accountId)

	res, err := sendRequest("GET", url, nil)
	if err != nil {
		return nil, err
	}

	var notificationList models.NotificationResponse
	err = json.Unmarshal(res, &notificationList)
	if err != nil {
		return nil, err
	}

	return &notificationList, nil
}
