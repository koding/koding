package emailmodels

import (
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMailerNotification(t *testing.T) {
	Convey("It should build mailer notification hash", t, func() {
		messages := []Messager{}

		m := MailerNotification{
			Hostname:         "http://dev.koding.com:8090",
			FirstName:        "Indiana",
			Username:         "indiana",
			Email:            "indiana@koding.com",
			MessageType:      "message in a bottle",
			UnsubscribeToken: "token",
			Messages:         messages,
		}

		results := m.ToMap()

		So(results["firstName"], ShouldEqual, "Indiana")
		So(results["unsubscribeLink"], ShouldEqual, "http://dev.koding.com:8090/Unsubscribe/token/indiana@koding.com")
		So(results["unsubscribeAllLink"], ShouldEqual, "http://dev.koding.com:8090/Unsubscribe/token/indiana@koding.com/all")
		So(len(results["messages"].([]map[string]interface{})), ShouldEqual, 0)
	})

	Convey("It should build notification message hash", t, func() {
		n := &NotificationMessage{
			Hostname:       "http://dev.koding.com",
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
		So(result["actorLink"], ShouldEqual, "http://dev.koding.com/indiana")
		So(result["messageLink"], ShouldEqual, "http://dev.koding.com/Activity/Post/raiders-of-the-last-ark")
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

func TestCodeblocks(t *testing.T) {
	Convey("It should output following codeblocks properly", t, func() {
		results := [][]string{
			{"", ""},
			{"empty", "empty"},
			{"```inside``` outside", "<pre>inside</pre> outside"},
			{"```inside``` outside ```another```", "<pre>inside</pre> outside <pre>another</pre>"},
			{"```inside\n``` outside", "<pre>inside\n</pre> outside"},
		}

		for _, result := range results {
			So(convertCodeBlocksToPre(result[0]), ShouldEqual, result[1])
		}
	})
}
