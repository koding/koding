package sender

import (
	"socialapi/config"
	"socialapi/workers/common/runner"
	"testing"

	"github.com/sendgrid/sendgrid-go"
	. "github.com/smartystreets/goconvey/convey"
)

func TestBongoName(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while testing bongo name", t, func() {
		Convey("do not add any future notifier if message type is not private message", func() {
			m := &Mail{}
			bn := m.BongoName()
			So(bn, ShouldEqual, "api.mail")
		})
	})

}

func TestNew(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)

	Convey("while creating new controller for Mail worker", t, func() {
		Convey("error should not be nil", func() {
			_ = &Mail{
				To:       "mehmet@koding.com",
				Subject:  "Test message",
				Text:     "Example",
				From:     "team@koding.com",
				FromName: "koding",
			}

			sg := sendgrid.NewSendGridClient(appConfig.Email.Username, appConfig.Email.Password)
			sgm := &SendGridMail{
				Sendgrid: sg,
			}
			c := New(r.Log, sgm)
			So(c, ShouldNotBeNil)
		})
	})
}

type fakeClient struct {
	mail *Mail
}

func (f *fakeClient) Send(mail *Mail) error {
	f.mail = mail
	return nil
}

func TestSend(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		t.Fatalf("couldn't start bongo %s", err.Error())
	}
	defer r.Close()

	Convey("while sending mail for Mail worker", t, func() {
		Convey("its property should be equal to Mail fields", func() {
			fc := &fakeClient{}
			c := New(r.Log, fc)
			So(c, ShouldNotBeNil)
			m := &Mail{
				To:       "mehmet@koding.com",
				Subject:  "Test message",
				Text:     "Example",
				From:     "mail@koding.com",
				FromName: "koding",
			}
			err := c.Process(m)
			So(err, ShouldBeNil)
			So("mehmet@koding.com", ShouldEqual, fc.mail.To)
			So(fc.mail.FromName, ShouldEqual, "koding")
		})
	})

}
