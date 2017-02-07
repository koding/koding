package machine

import (
	"errors"
	"testing"
	"time"

	"koding/klient/remote/kitepinger"
	"koding/klient/testutil"

	"github.com/koding/kite/dnode"

	. "github.com/smartystreets/goconvey/convey"
)

type fakePinger struct {
	ReturnStatus kitepinger.Status
}

func (p *fakePinger) Ping() kitepinger.Status {
	return p.ReturnStatus
}

type fakeTransport struct {
	DialError error
	DialCount int

	TellWithTimeoutRequest     []interface{}
	ReturnTellWithTimeout      *dnode.Partial
	ReturnTellWithTimeoutError error
}

func (t *fakeTransport) Tell(string, ...interface{}) (*dnode.Partial, error) {
	return nil, nil
}

func (t *fakeTransport) TellWithTimeout(_ string, _ time.Duration, req ...interface{}) (*dnode.Partial, error) {
	t.TellWithTimeoutRequest = req
	return t.ReturnTellWithTimeout, t.ReturnTellWithTimeoutError
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

func TestWaitUntilOnline(tt *testing.T) {
	const grace = 20 * time.Millisecond
	const timeout = 50 * time.Millisecond

	Convey("Give a Machine", tt, func() {
		m := &Machine{}

		Convey("That is online", func() {
			m.HTTPTracker = kitepinger.NewPingTracker(&fakePinger{
				ReturnStatus: kitepinger.Success,
			})
			m.HTTPTracker.Start()

			Convey("It should send immediately", func() {
				start := time.Now()
				select {
				case <-m.WaitUntilOnline():
				case <-time.After(timeout):
				}
				So(time.Now(), ShouldHappenWithin, grace, start)
			})
		})

		Convey("That is offline", func() {
			m.HTTPTracker = kitepinger.NewPingTracker(&fakePinger{
				ReturnStatus: kitepinger.Failure,
			})
			m.HTTPTracker.Start()

			Convey("It should block", func() {
				start := time.Now()
				select {
				case <-m.WaitUntilOnline():
				case <-time.After(timeout):
				}
				So(time.Now(), ShouldNotHappenWithin, grace, start)
			})
		})

		Convey("That is eventually online", func() {
			p := &fakePinger{
				ReturnStatus: kitepinger.Failure,
			}
			m.HTTPTracker = kitepinger.NewPingTracker(p)
			m.HTTPTracker.Start()

			// Wait for 25ms, then set it to success
			time.AfterFunc(25*time.Millisecond, func() {
				p.ReturnStatus = kitepinger.Success
			})

			Convey("It should block until online", func() {
				start := time.Now()
				select {
				case <-m.WaitUntilOnline():
				case <-time.After(timeout):
				}
				// It should block for 25ms, with an additional 10ms for runtime to be safe.
				So(time.Now(), ShouldNotHappenWithin, 35*time.Millisecond, start)
			})
		})
	})
}

func TestDoesRemoteDirExist(tt *testing.T) {
	Convey("Given a machine", tt, func() {
		t := &fakeTransport{}
		m := &Machine{
			Transport: t,
		}

		Convey("With a remote dir that exists", func() {
			t.ReturnTellWithTimeout = &dnode.Partial{Raw: []byte(`{"exists":true, "isDir":true}`)}

			Convey("It should return true", func() {
				exists, err := m.DoesRemoteDirExist("foo")
				So(err, ShouldBeNil)
				So(exists, ShouldBeTrue)
			})
		})

		Convey("With a remote dir that does not exist", func() {
			t.ReturnTellWithTimeout = &dnode.Partial{Raw: []byte(`{"exists":false, "isDir":false}`)}

			Convey("It should return false", func() {
				exists, err := m.DoesRemoteDirExist("foo")
				So(err, ShouldBeNil)
				So(exists, ShouldBeFalse)
			})
		})

		Convey("With a remote path that does exist, but is not a dir", func() {
			t.ReturnTellWithTimeout = &dnode.Partial{Raw: []byte(`{"exists":true, "isDir":false}`)}

			Convey("It should return false", func() {
				exists, err := m.DoesRemoteDirExist("foo")
				So(err, ShouldBeNil)
				So(exists, ShouldBeFalse)
			})
		})
	})
}
