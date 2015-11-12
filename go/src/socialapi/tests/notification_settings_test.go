package main

import (
	"socialapi/models"
	"socialapi/rest"
	"socialapi/workers/common/response"
	"socialapi/workers/common/tests"
	"testing"

	"github.com/cihangir/nisql"
	"github.com/koding/runner"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetNotificationSetting(t *testing.T) {
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
					ns, err := rest.GetNotificationSetting(channel.Id, ses.ClientId)
					So(err, ShouldNotBeNil)
					So(err.Error(), ShouldContainSubstring, response.ErrContentNotFound.Error())
					So(ns, ShouldBeNil)
				})
				Convey("We should be able to create notification settings", func() {
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

					Convey("We should be able to get the created notification settings", func() {
						newNs, err := rest.GetNotificationSetting(ns.ChannelId, ses.ClientId)
						So(err, ShouldBeNil)
						So(newNs.AccountId, ShouldEqual, account.Id)
					})
				})
			})
		})
	})
}

func TestCreateNotificationSetting(t *testing.T) {
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

					Convey("We should be able to update the created notification settings", func() {
						ns.DesktopSetting = nisql.String(models.NotificationSetting_STATUS_NEVER)
						newNs, err := rest.UpdateNotificationSetting(ns, ses.ClientId)
						So(err, ShouldBeNil)
						So(*newNs.DesktopSetting.Get(), ShouldEqual, *ns.DesktopSetting.Get())
					})
				})
			})
		})
	})
}

func TestDeleteNotificationSetting(t *testing.T) {
	tests.WithRunner(t, func(r *runner.Runner) {
		Convey("While deleting notification settings", t, func() {
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
					n := &models.NotificationSetting{
						ChannelId:      channel.Id,
						AccountId:      account.Id,
						DesktopSetting: nisql.String(models.NotificationSetting_STATUS_ALL),
						MobileSetting:  nisql.NullString{},
						IsMuted:        nisql.Bool(false),
						IsSuppressed:   nisql.NullBool{},
					}
					ns, err := rest.CreateNotificationSetting(n, ses.ClientId)
					So(err, ShouldBeNil)
					So(*ns.IsMuted.Get(), ShouldEqual, false)
					Convey("We should be not able to delete the created notification settings", func() {
						ns.DesktopSetting = nisql.String(models.NotificationSetting_STATUS_PERSONAL)
						err = rest.DeleteNotificationSetting(ns.Id, ses.ClientId)
						So(err, ShouldBeNil)
					})
				})
			})
		})
	})
}
