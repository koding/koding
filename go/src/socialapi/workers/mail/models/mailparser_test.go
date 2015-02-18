package models

import (
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

	Convey("while testing get account", t, func() {
		Convey("Function should return blank if parameter is empty", func() {
			So(GetAccount(), ShouldBeBlank)
		})

		Convey("function return empty if parameter is invalid", func() {
			acc, _ := GetAccount("interestingEmail@somethinglikethat")
			So(acc, ShouldBeEmpty)
		})

		Convey("function return empty if parameter is empty", func() {
			acc, _ := GetAccount("")
			So(acc, ShouldBeEmpty)
		})
	})
}

func TestValidate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

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
			So(m.Validate(), ShouldNotBeNil)
		})
	})
}

func TestPersist(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldnt start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while testing Persist", t, func() {
		Convey("", func() {
			m := &Mail{From: "mehmet@koding.com",
				OriginalRecipient: "post+channelid.5678@inbound.koding.com",
				MailboxHash:       "channelid.5678",
				TextBody:          "Its a example of text message",
			}

			acc := socialapimodels.CreateAccountWithTest()
			cm := socialapimodels.NewChannelMessage()
			cm.c

			err := m.Persist()
			So(err, ShouldContainSubstring, "")
		})

	})
}
