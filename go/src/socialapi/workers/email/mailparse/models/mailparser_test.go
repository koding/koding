package models

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"testing"

	"github.com/koding/bongo"
	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestGetAccount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while testing get account", t, func() {
		Convey("returns empty if parameter is invalid", func() {
			acc, err := GetAccount("interestingEmail@somethinglikethat")
			So(err, ShouldNotBeNil)
			So(acc, ShouldBeNil)
		})

		Convey("returns empty if parameter is empty", func() {
			acc, err := GetAccount("")
			So(err, ShouldNotBeNil)
			So(acc, ShouldBeNil)
		})

		Convey("Should return blank if parameter is empty", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From: mongoUser.Email,
			}
			ga, err := GetAccount(m.From)
			So(err, ShouldBeNil)
			So(ga, ShouldNotBeNil)
		})

	})
}

func TestValidate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while testing Validate", t, func() {
		Convey("From field of Mail struct should not be empty, otherwise return err", func() {
			m := &Mail{}
			err := m.Validate()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrFromFieldIsNotSet)
		})

		Convey("TextBody field of Mail struct should not be empty, otherwise return err", func() {
			m := &Mail{From: "mehmet@koding.com"}
			err := m.Validate()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrTextBodyIsNotSet)
		})

		Convey("returns nil if Mail struct is set ", func() {
			m := &Mail{From: "mehmet@koding.com", TextBody: "Some text parapraph"}
			So(m.Validate(), ShouldBeNil)
		})
	})
}

func TestGetIdsFromMailboxHash(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while getting ids from mailboxhash", t, func() {

		Convey("returns error if 1.index of mailboxhash doesn't exist", func() {
			m := &Mail{
				MailboxHash: "message.",
			}

			gid, err := m.getIdsFromMailboxHash()
			So(err, ShouldNotBeNil)
			So(gid, ShouldEqual, 0)
		})

		Convey("returns error if 1.index doesn't exist", func() {
			m := &Mail{
				MailboxHash: "message.1234",
			}

			gid, err := m.getIdsFromMailboxHash()
			So(err, ShouldBeNil)
			So(gid, ShouldEqual, 1234)
		})
	})
}

func TestGetSocialIdFromEmail(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while getting account id in the mail", t, func() {
		Convey("From fields should be saved in db, otherwise return err", func() {

			m := &Mail{
				From: "mailisnotexist@abo",
			}

			gid, err := m.getSocialIdFromEmail()
			So(err, ShouldNotBeNil)
			So(err, ShouldEqual, ErrEmailIsNotFetched)
			So(gid, ShouldEqual, 0)
		})

		Convey("should not be any error if all is well", func() {

			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From: mongoUser.Email,
			}

			gid, err := m.getSocialIdFromEmail()
			So(err, ShouldBeNil)
			So(gid, ShouldEqual, acc.Id)

		})

	})
}

func TestPersist(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	Convey("while testing Persist", t, func() {

		Convey("testing post message while all is well", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			c := socialapimodels.CreateChannelWithTest(acc.Id)

			//cm := socialapimodels.CreateMessage(c.Id, acc.Id)
			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From:              mongoUser.Email,
				OriginalRecipient: fmt.Sprintf("post+channelid.%d@inbound.koding.com", c.Id),
				MailboxHash:       fmt.Sprintf("channelid.%d", c.Id),
				TextBody:          "Its an example of text message",
			}

			err = m.Persist()
			So(err, ShouldBeNil)
		})

		Convey("reply should have messageid", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			c := socialapimodels.CreateChannelWithTest(acc.Id)
			socialapimodels.AddParticipantsWithTest(c.Id, acc.Id)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From:              mongoUser.Email,
				OriginalRecipient: fmt.Sprintf("reply+channelid.%d@inbound.koding.com", c.Id),
				MailboxHash:       fmt.Sprintf("channelid.%d", c.Id),
				TextBody:          "Its an example of text message",
			}

			err = m.Persist()
			So(err, ShouldEqual, bongo.RecordNotFound)
		})

		Convey("testing reply message if all is well", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			c := socialapimodels.CreateChannelWithTest(acc.Id)
			socialapimodels.AddParticipantsWithTest(c.Id, acc.Id)

			cm := socialapimodels.CreateMessage(c.Id, acc.Id, socialapimodels.ChannelMessage_TYPE_POST)
			So(cm, ShouldNotBeNil)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From:              mongoUser.Email,
				OriginalRecipient: fmt.Sprintf("reply+messageid.%d@inbound.koding.com", c.Id),
				MailboxHash:       fmt.Sprintf("messageid.%d", cm.Id),
				TextBody:          "Its an example of text message",
				StrippedTextReply: "This one is reply message",
			}

			err = m.Persist()
			So(err, ShouldBeNil)
		})

		Convey("testing reply message, record not found if user is not a participant", func() {
			acc, err := socialapimodels.CreateAccountInBothDbs()
			So(err, ShouldBeNil)

			c := socialapimodels.CreateChannelWithTest(acc.Id)

			cm := socialapimodels.CreateMessage(c.Id, acc.Id, socialapimodels.ChannelMessage_TYPE_POST)
			So(cm, ShouldNotBeNil)

			mongoUser, err := modelhelper.GetUser(acc.Nick)
			So(err, ShouldBeNil)

			m := &Mail{
				From:              mongoUser.Email,
				OriginalRecipient: fmt.Sprintf("reply+messageid.%d@inbound.koding.com", c.Id),
				MailboxHash:       fmt.Sprintf("messageid.%d", cm.Id),
				TextBody:          "Its an example of text message",
				StrippedTextReply: "This one is reply message",
			}

			err = m.persistPost(acc.Id)
			So(err, ShouldNotBeNil)
		})
	})
}
