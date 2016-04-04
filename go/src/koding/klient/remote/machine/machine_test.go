package machine

import (
	"errors"
	"testing"
	"time"

	"koding/klient/testutil"

	"github.com/koding/kite/dnode"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeTransport struct {
	DialError error
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
	return t.DialError
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

		Convey("It should set hasDialed true", func() {
			So(m.Dial(), ShouldBeNil)
			So(m.hasDialed, ShouldBeTrue)
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

	Convey("Given the machines transport fails Dialing", tt, func() {
		t := &fakeTransport{DialError: errors.New("foo")}
		m := &Machine{
			Transport: t,
			Log:       testutil.DiscardLogger,
		}

		Convey("It should return the error", func() {
			So(m.Dial(), ShouldNotBeNil)
			So(t.DialCount, ShouldEqual, 1)
		})

		// Set it to true, for testing purposes.
		m.hasDialed = true
		Convey("It should set hasDialed to false", func() {
			So(m.Dial(), ShouldNotBeNil)
			So(m.hasDialed, ShouldBeFalse)
		})
	})
}

func TestMachineDialOnce(tt *testing.T) {
	Convey("Given the machines transport successfully Dials", tt, func() {
		t := &fakeTransport{}
		m := &Machine{
			Transport: t,
			Log:       testutil.DiscardLogger,
		}

		Convey("It should only allow dialing once", func() {
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 1)
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 1)
		})
	})

	Convey("Given the machines transport fails Dialing", tt, func() {
		t := &fakeTransport{DialError: errors.New("foo")}
		m := &Machine{
			Transport: t,
			Log:       testutil.DiscardLogger,
		}

		Convey("It should return the error", func() {
			So(m.DialOnce(), ShouldNotBeNil)
		})

		Convey("It should allow repeated dials", func() {
			So(m.DialOnce(), ShouldNotBeNil)
			So(t.DialCount, ShouldEqual, 1)
			So(m.DialOnce(), ShouldNotBeNil)
			So(t.DialCount, ShouldEqual, 2)
			So(m.DialOnce(), ShouldNotBeNil)
			So(t.DialCount, ShouldEqual, 3)
		})
	})

	Convey("Given a failing Dial is called after DialOnce succeeds", tt, func() {
		t := &fakeTransport{}
		m := &Machine{
			Transport: t,
			Log:       testutil.DiscardLogger,
		}

		// This test is a bit broad / convoluted for DialOnce, but testing the specific
		// DialOnce scenario is worth it - just to test the whole scope of the scenario.
		Convey("It Dial once just as expected", func() {
			// Setup our scenario, and test the scenario for sanity
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 1)
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 1)

			// Now set a dial error for Dial() to fail with
			t.DialError = errors.New("Dial error")
			So(m.Dial(), ShouldNotBeNil)
			So(t.DialCount, ShouldEqual, 2)
			// Now clear the error so DialOnce can succeed
			t.DialError = nil

			// And finally, re-dialonce and make sure dialonce runs once as expected.
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 3)
			So(m.DialOnce(), ShouldBeNil)
			So(t.DialCount, ShouldEqual, 3)
		})
	})
}
