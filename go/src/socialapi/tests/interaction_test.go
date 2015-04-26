package main

import (
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/rest"
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestInteractionLikedMessages(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("While testing listing of the liked messages", t, func() {
		groupName := "koding"

		account1 := models.NewAccount()
		account1.OldId = AccountOldId.Hex()
		account, err := rest.CreateAccount(account1)
		So(err, ShouldBeNil)
		So(account, ShouldNotBeNil)

		ses, err := models.FetchOrCreateSession(account.Nick)
		So(err, ShouldBeNil)
		So(ses, ShouldNotBeNil)

		groupChannel, err := rest.CreateChannelByGroupNameAndType(account.Id, groupName, models.Channel_TYPE_GROUP)
		So(err, ShouldBeNil)
		So(groupChannel, ShouldNotBeNil)

		post, err := rest.CreatePost(groupChannel.Id, account.Id)
		So(err, ShouldBeNil)
		So(post, ShouldNotBeNil)

		_, err = rest.AddInteraction("like", post.Id, account.Id)
		So(err, ShouldBeNil)
		Convey("We should be able to list the messages that liked", func() {
			likes, err := rest.GetInteractions("like", post.Id)
			So(err, ShouldBeNil)
			So(len(likes), ShouldEqual, 1)
			interactedMessages, err := rest.ListMessageInteractionsByType(models.Interaction_TYPE_LIKE, account.Id, ses.ClientId)
			So(err, ShouldBeNil)
			So(len(interactedMessages), ShouldEqual, 1)
		})
	})
}
