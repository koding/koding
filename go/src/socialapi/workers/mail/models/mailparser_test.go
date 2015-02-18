package models

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestGetAccount(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while testing get account", t, func() {
		Convey("function return empty if parameter is invalid", func() {
			acc, err := GetAccount("interestingEmail@somethinglikethat")
			So(err, ShouldNotBeNil)
			So(acc, ShouldBeNil)
		})

		Convey("function return empty if parameter is empty", func() {
			acc, err := GetAccount("")
			So(err, ShouldNotBeNil)
			So(acc, ShouldBeNil)
		})

		Convey("Function should return blank if parameter is empty", func() {
			ga, err := GetAccount("mehmet@koding.com")
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
	modelhelper.Initialize(r.Conf.Mongo)
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

		Convey("Function return nil if Mail struct is set ", func() {
			m := &Mail{From: "mehmet@koding.com", TextBody: "Some text parapraph"}
			So(m.Validate(), ShouldBeNil)
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
	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	Convey("while testing Persist", t, func() {
		Convey("testing post message", func() {
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
	})
}
