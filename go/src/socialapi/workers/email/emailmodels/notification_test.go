package emailmodels

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMailerNotification(t *testing.T) {
	Convey("It should build mailer notification hash", t, func() {
		messages := []Message{}

		m := MailerNotification{
			FirstName:   "Indiana",
			Username:    "indiana",
			Email:       "indiana@koding.com",
			MessageType: "message in a bottle",
			Messages:    messages,
		}

		results := m.ToMap()

		So(results["firstName"], ShouldEqual, "Indiana")
		So(len(results["messages"].([]map[string]interface{})), ShouldEqual, 0)
	})

	Convey("It should build notification message hash", t, func() {
		n := &NotificationMessage{
			Hostname:       "http://lvh.me",
			Actor:          "Indiana",
			ActorHash:      "1",
			ActorSlug:      "indiana",
			Message:        "Raiders of the last Ark",
			MessageSlug:    "raiders-of-the-last-ark",
			Action:         "commented on",
			ActionType:     "post",
			CreatedAt:      time.Date(1981, time.June, 1, 00, 0, 0, 0, time.UTC),
			TimezoneOffset: 0,
		}

		result := n.ToMap()

		So(result["actorAvatar"], ShouldEqual, "https://gravatar.com/avatar/1?size=35&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fsquare-avatars%2Fdefault.avatar.35.png")
		So(result["actorLink"], ShouldEqual, "http://lvh.me/indiana")
		So(result["messageLink"], ShouldEqual, "http://lvh.me/Activity/Post/raiders-of-the-last-ark")
		So(result["createdAt"], ShouldEqual, "12:00 AM")
	})

	Convey("It should build private message hash", t, func() {
		p := &PrivateMessage{
			Actor:     "Indiana",
			Message:   "Raiders of the last Ark",
			CreatedAt: "11:00 PM",
		}

		pc := &PrivateMessageChannel{
			NestedMessages: []*PrivateMessage{p},
			Subtitle:       "subtitle",
			ActorHash:      "1",
		}

		result := pc.ToMap()

		So(result["actorAvatar"], ShouldEqual, "https://gravatar.com/avatar/1?size=35&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fsquare-avatars%2Fdefault.avatar.35.png")
		So(len(result["nestedMessages"].([]map[string]interface{})), ShouldEqual, 1)
	})
}
