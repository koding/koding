package emailmodels

import (
	"koding/db/mongodb/modelhelper"
	"math/rand"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestMessageGroupSummaryBuilder(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	modelhelper.Initialize(r.Conf.Mongo)

	rand.Seed(time.Now().UnixNano())
	account1, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("error occurred: %s", err)
	}
	account2, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("error occurred: %s", err)
	}
	account3, err := models.CreateAccountInBothDbs()
	if err != nil {
		t.Fatalf("error occurred: %s", err)
	}

	Convey("While building message group summary", t, func() {
		messages := make([]models.ChannelMessage, 0)
		message := models.ChannelMessage{}
		message.Body = "message1"
		message.AccountId = account1.Id
		messages = append(messages, message)
		Convey("it must contain single message group when there is only one message", func() {
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 1)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
			So(len(mgs[0].Messages), ShouldEqual, 1)
		})

		Convey("it must contain two message groups when there are two message from different users", func() {
			message2 := models.ChannelMessage{}
			message2.Body = "message2"
			message2.AccountId = account2.Id
			messages = append(messages, message2)
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 2)
			So(len(mgs[1].Messages), ShouldEqual, 1)
			So(len(mgs[0].Messages), ShouldEqual, 1)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
			So(mgs[1].AccountId, ShouldEqual, account2.Id)
		})

		Convey("it must contain one message group when there are two messages from same user", func() {
			message2 := models.ChannelMessage{}
			message2.Body = "message2"
			message2.AccountId = account1.Id
			messages = append(messages, message2)
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 1)
			So(len(mgs[0].Messages), ShouldEqual, 2)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
		})

		Convey("it must contain two different groups when first message is sent by account 1 and second and third messages are sent by account 2", func() {
			message2 := models.ChannelMessage{}
			message2.Body = "message2"
			message2.AccountId = account2.Id
			message3 := models.ChannelMessage{}
			message3.Body = "message3"
			message3.AccountId = account2.Id
			messages = append(messages, message2, message3)
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 2)
			So(len(mgs[0].Messages), ShouldEqual, 1)
			So(len(mgs[1].Messages), ShouldEqual, 2)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
			So(mgs[1].AccountId, ShouldEqual, account2.Id)
		})

		Convey("it must contain three different groups when first message and third messages are sent by account 1 and second message is sent by account 2", func() {
			message2 := models.ChannelMessage{}
			message2.Body = "message2"
			message2.AccountId = account2.Id
			message3 := models.ChannelMessage{}
			message3.Body = "message3"
			message3.AccountId = account1.Id
			messages = append(messages, message2, message3)
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 3)
			So(len(mgs[0].Messages), ShouldEqual, 1)
			So(len(mgs[1].Messages), ShouldEqual, 1)
			So(len(mgs[2].Messages), ShouldEqual, 1)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
			So(mgs[1].AccountId, ShouldEqual, account2.Id)
			So(mgs[2].AccountId, ShouldEqual, account1.Id)
		})

		Convey("it must contain three different groups when messages are from different users", func() {
			message2 := models.ChannelMessage{}
			message2.Body = "message2"
			message2.AccountId = account2.Id
			message3 := models.ChannelMessage{}
			message3.Body = "message3"
			message3.AccountId = account3.Id
			messages = append(messages, message2, message3)
			mgs, err := buildMessageSummaries(messages)
			So(err, ShouldBeNil)
			So(len(mgs), ShouldEqual, 3)
			So(len(mgs[0].Messages), ShouldEqual, 1)
			So(len(mgs[1].Messages), ShouldEqual, 1)
			So(len(mgs[2].Messages), ShouldEqual, 1)
			So(mgs[0].AccountId, ShouldEqual, account1.Id)
			So(mgs[1].AccountId, ShouldEqual, account2.Id)
			So(mgs[2].AccountId, ShouldEqual, account3.Id)
		})
	})

}

func TestRenderChannel(t *testing.T) {
	SkipConvey("Channel should be able to rendered", t, func() {
		cs := &ChannelSummary{}
		cs.UnreadCount = 2
		messages := make([]*MessageGroupSummary, 0)
		mgs1 := NewMessageGroupSummary()
		ms1 := &MessageSummary{}
		ms1.Body = "hehe"
		ms1.Time = "2:40 PM"
		mgs1.AddMessage(ms1)
		mgs1.Hash = "123123"
		mgs1.Nickname = "canthefason"

		mgs2 := NewMessageGroupSummary()
		ms2 := &MessageSummary{}
		ms2.Body = "hoho"
		ms2.Time = "2:38 PM"
		mgs2.Nickname = "kodingcan"
		mgs2.Hash = "456456"
		mgs2.AddMessage(ms2)
		cs.MessageGroups = append(messages, mgs1, mgs2)

		body, err := cs.Render()
		So(err, ShouldBeNil)
		So(body, ShouldContainSubstring, "hehe")
		So(body, ShouldContainSubstring, "123123")
		So(body, ShouldContainSubstring, "canthefason")
		So(body, ShouldContainSubstring, "2:40 PM")

		So(body, ShouldContainSubstring, "hoho")
		So(body, ShouldContainSubstring, "456456")
		So(body, ShouldContainSubstring, "kodingcan")
		So(body, ShouldContainSubstring, "2:38 PM")
		So(body, ShouldContainSubstring, "You have 2 new messages:")
	})
}

// func TestGetTitle(t *testing.T) {
// 	SkipConvey("Channel title should be able to rendered", t, func() {
// 		Convey("when channel unread count is 1", func() {
// 			title := getTitle(1)
// 			So(title, ShouldEqual, "You have 1 new message:")
// 		})

// 		Convey("when channel unread count is more than one", func() {
// 			title := getTitle(3)
// 			So(title, ShouldEqual, "You have 3 new messages:")
// 		})
// 	})
// }
