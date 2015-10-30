package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetNotificationSettings(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While getting notification settings", t, func() {
			Convey("we should be able to create channel ", func() {
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

				Convey("We should be not able to fetch default settings", func() {
					ns, err := rest.GetNotificationSettings(channel.Id, account.Id)
					So(err, ShouldNotBeNil)
					fmt.Println("err is : ", err)
					fmt.Println("notification settings is : ", ns)

				})
			})
		})
	})
}

func TestCreateNotificationSettings(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While updating notification settings", t, func() {
			Convey("we should be able to create channel ", func() {
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

				Convey("We should be not able to create notification settings", func() {
					n := &models.NotificationSettings{
						ChannelId:      channel.Id,
						AccountId:      account.Id,
						DesktopSetting: models.NotificationSettings_STATUS_ALL,
						MobileSetting:  models.NotificationSettings_STATUS_ALL,
						IsMuted:        false,
						IsSuppressed:   false,
					}
					ns, err := rest.CreateNotificationSettings(n, ses.ClientId)
					So(err, ShouldNotBeNil)
					fmt.Println("err is : ", err)
					fmt.Println("notification settings is : ", ns)

					Convey("We should be not able to update created notification settings", func() {
						ns.DesktopSetting = models.NotificationSettings_STATUS_PERSONAL
						newNs, err := rest.UpdateNotificationSettings(ns, ses.ClientId)
						So(err, ShouldNotBeNil)
						So(newNs.DesktopSetting, ShouldEqual, ns.DesktopSetting)
						fmt.Println("err is : ", err)
						fmt.Println("notification settings is : ", ns)
					})
				})
			})
		})
	})
}
