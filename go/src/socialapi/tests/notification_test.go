package main

import (
	. "github.com/smartystreets/goconvey/convey"
	"socialapi/models"
	"testing"
	"fmt"
	"encoding/json"
)

func TestNotificationCreation(t *testing.T) {
	Convey("while testing reply notifications", t, func() {
		ownerAccount := models.NewAccount()
		firstUser := models.NewAccount()
		secondUser := models.NewAccount()
		thirdUser := models.NewAccount()
		forthUser := models.NewAccount()
		testGroupChannel := models.NewChannel()

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

			var cm *models.ChannelMessage
			var replyMessage *models.ChannelMessage
			Convey("I should be able to create channel message", func() {
				messageBody := "notification first message"
				var err error
				cm, err = createPostWithBody(testGroupChannel.Id, ownerAccount.Id, messageBody)
				ResultedWithNoErrorCheck(cm, err)
			})

			Convey("First user should be able to reply it", func() {
				var err error
				replyMessage, err = addReply(cm.Id, firstUser.Id)
				ResultedWithNoErrorCheck(replyMessage, err)
			})

			Convey("I should be able to receive notification", func() {
				// nl, err := getNotificationList(ownerAccount.Id)
				// ResultedWithNoErrorCheck(nl, err)

				Convey("And Notification list should contain one notification", func() {
					// So(len(nl.Notifications), ShouldEqual, 1)
					Convey("Notification should contain first user as Latest Actors", func() {
						// So(len(nl.Notifications[0].Actors.LatestActors), ShouldEqual, firstUser.Id)
						// So(nl.Notifications[0].Actors.LatestActors[0], ShouldEqual, firstUser.Id)
					})
					Convey("Notifier count should be 1", func() {
						// So(nl.Notifications[0].Actors.Count, ShouldEqual, 1)
					})
				})

				Convey("And Unread notification count should be 1 ", func() {
					// So(nl.UnreadCount, ShouldEqual, 1)
				})


			})

			Convey("Second user should be able to reply it", nil)

			Convey("I should be able to receive notification", func() {

				Convey("Notification should contain second and first user consecutively", nil)

				Convey("Notifier count should be 2", nil)

			})

			Convey("Third user should be able to reply it", nil)

			Convey("I should be able to receive notification", func() {

				Convey("Notification should contain third, second and first user consecutively", nil)

				Convey("Notifier count should be 3", nil)

			})

			Convey("Forth user should be able to reply it", nil)

			Convey("I should be able to receive notification", func() {

				Convey("Notification should contain forth, third and second user consecutively", nil)

				Convey("Notifier count should be 4", nil)

			})

			Convey("First user should be able to reply it", nil)

			Convey("I should be able to receive notification", func() {

				Convey("Notification should contain first, forth, and third user consecutively", nil)

				Convey("Notifier count should be 4", nil)

			})

		})

		Convey("As a message owner I must not be notified by my own replies", func() {

			Convey("I should be able to create channel message", nil)

			Convey("I should be able to reply my message", nil)

			Convey("I should not receive notification", nil)

			Convey("Another user should be able to reply it", nil)

			Convey("I should be able to receive notification", func() {

				Convey("Notification should contain first user as Latest Actors", nil)

				Convey("Notifier count should be 1", nil)

			})

		})

	})

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
