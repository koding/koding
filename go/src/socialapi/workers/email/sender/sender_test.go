package sender

import (
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

	Convey("while creating new controller for Mail worker", t, func() {
		Convey("it should return Controller struct", func() {
			sg := sendgrid.NewSendGridClient(r.Conf.Email.Username, r.Conf.Email.Password)
			c := New(r.Log, sg)
			So(c, ShouldNotBeNil)

		})
	})

}
