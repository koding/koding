package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/response"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetNotificationSettings(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While getting notification settings", t, func() {
			Convey("after create channel and account requirements", func() {
				groupName := models.RandomGroupName()

				account, err := models.CreateAccountInBothDbsWithNick("sinan")
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)

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

				Convey("We should be able to fetch default settings", func() {
					ns, err := rest.GetNotificationSettings(channel.Id, ses.ClientId)
					So(err, ShouldNotBeNil)
					So(err.Error(), ShouldContainSubstring, response.ErrContentNotFound.Error())
					So(ns, ShouldBeNil)
				})
				Convey("We should be able to create notification settings", func() {
					n := &models.NotificationSettings{
						ChannelId:      channel.Id,
						AccountId:      account.Id,
						DesktopSetting: models.NotificationSettings_STATUS_ALL,
						MobileSetting:  models.NotificationSettings_STATUS_ALL,
						IsMuted:        false,
						IsSuppressed:   true,
					}
					ns, err := rest.CreateNotificationSettings(n, ses.ClientId)
					So(err, ShouldBeNil)
					So(ns.AccountId, ShouldEqual, account.Id)
					So(ns.IsSuppressed, ShouldEqual, true)
					fmt.Println("Notification setting channel id is --->>", ns.ChannelId)

					Convey("We should be able to get the created notification settings", func() {
						newNs, err := rest.GetNotificationSettings(ns.ChannelId, ses.ClientId)
						So(err, ShouldBeNil)
						fmt.Println("Err is :-->>>>>>", err)
						fmt.Println("newNotificationSetting is :-->>>>>>", newNs)
					})
				})
			})
		})
	})
}

func TestCreateNotificationSettings(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While updating notification settings", t, func() {
			Convey("after create channel and account requirements", func() {
				groupName := models.RandomGroupName()

				account, err := models.CreateAccountInBothDbsWithNick("sinan")
				So(err, ShouldBeNil)
				So(account, ShouldNotBeNil)

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

				Convey("We should be able to create notification settings", func() {
					n := &models.NotificationSettings{
						ChannelId:      channel.Id,
						AccountId:      account.Id,
						DesktopSetting: models.NotificationSettings_STATUS_ALL,
						MobileSetting:  models.NotificationSettings_STATUS_ALL,
						IsMuted:        false,
						IsSuppressed:   true,
					}
					ns, err := rest.CreateNotificationSettings(n, ses.ClientId)
					So(err, ShouldBeNil)
					So(ns.AccountId, ShouldEqual, account.Id)
					So(ns.IsSuppressed, ShouldEqual, true)

					Convey("We should be able to update the created notification settings", func() {
						ns.DesktopSetting = models.NotificationSettings_STATUS_PERSONAL
						newNs, err := rest.UpdateNotificationSettings(ns, ses.ClientId)
						So(err, ShouldBeNil)
						So(newNs.DesktopSetting, ShouldEqual, ns.DesktopSetting)
					})
				})
			})
		})
	})
}

// func TestDeleteNotificationSettings(t *testing.T) {
// 	tests.WithRunner(t, func(r *runner.Runner) {
// 		Convey("While deleting notification settings", t, func() {
// 			Convey("after create channel and account requirements", func() {
// 				groupName := models.RandomGroupName()

// 				account, err := models.CreateAccountInBothDbsWithNick("sinan")
// 				So(err, ShouldBeNil)
// 				So(account, ShouldNotBeNil)

// 				ses, err := models.FetchOrCreateSession(account.Nick, groupName)
// 				So(err, ShouldBeNil)
// 				So(ses, ShouldNotBeNil)

// 				channel := models.CreateTypedGroupedChannelWithTest(
// 					account.Id,
// 					models.Channel_TYPE_GROUP,
// 					groupName,
// 				)
// 				_, err = channel.AddParticipant(account.Id)
// 				So(err, ShouldBeNil)

// 				Convey("We should be able to create notification settings", func() {
// 					n := &models.NotificationSettings{
// 						ChannelId:      channel.Id,
// 						AccountId:      account.Id,
// 						DesktopSetting: models.NotificationSettings_STATUS_ALL,
// 						MobileSetting:  models.NotificationSettings_STATUS_ALL,
// 						IsMuted:        false,
// 						IsSuppressed:   true,
// 					}
// 					ns, err := rest.CreateNotificationSettings(n, ses.ClientId)
// 					So(err, ShouldBeNil)
// 					So(ns.IsMuted, ShouldEqual, false)
// 					Convey("We should be not able to delete the created notification settings", func() {
// 						ns.DesktopSetting = models.NotificationSettings_STATUS_PERSONAL
// 						err = rest.DeleteNotificationSettings(ns.Id)
// 						So(err, ShouldBeNil)
// 					})
// 				})
// 			})
// 		})
// 	})
// }
