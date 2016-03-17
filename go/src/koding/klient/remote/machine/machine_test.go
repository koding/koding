package machine

import (
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite/dnode"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeTransport struct {
	DialCount int
}

func (t *fakeTransport) Tell(string, ...interface{}) (*dnode.Partial, error) {
	return nil, nil
}

func (t *fakeTransport) TellWithTimeout(string, time.Duration, ...interface{}) (*dnode.Partial, error) {
	return nil, nil
}

func (t *fakeTransport) Dial() error {
	t.DialCount++
	return nil
}

func TestMachineDial(tt *testing.T) {
	Convey("Given the machine has a Transport", tt, func() {
		t := &fakeTransport{}
		m := &Machine{
			Transport: t,
			Log:       testutil.DiscardLogger,
		}

		Convey("It should call Dial", func() {
			So(m.Dial(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 1)
		})
	})

	Convey("Given the machine does not have a Transport", tt, func() {
		m := &Machine{
			Log: testutil.DiscardLogger,
		}

		Convey("It should not panic", func() {
			So(func() { m.Dial() }, ShouldNotPanic)
			So(m.Dial(), ShouldNotBeNil)
		})
	})
}
