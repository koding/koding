package mount

import (
	"errors"
	"testing"
	"time"

	"koding/klient/remote/kitepinger"
	"koding/klient/remote/machine"
	"koding/klient/remote/req"
	"koding/klient/testutil"

	"github.com/koding/kite/dnode"

	. "github.com/smartystreets/goconvey/convey"
)

type fakeTransport struct {
	TripResponses map[string]*dnode.Partial
	TripErrors    map[string]error
}

func (f *fakeTransport) Dial() error {
	return nil
}

func (f *fakeTransport) TellWithTimeout(methodName string, _ time.Duration, reqs ...interface{}) (*dnode.Partial, error) {
	return f.Tell(methodName, reqs...)
}

func (f *fakeTransport) Tell(methodName string, reqs ...interface{}) (res *dnode.Partial, err error) {
	if f.TripErrors != nil {
		err, _ = f.TripErrors[methodName]
	}

	if f.TripResponses != nil {
		res, _ = f.TripResponses[methodName]
	}

	return res, err
}

func TestHandleChangeSummary(t *testing.T) {
	Convey("Given an OldStatus of Failure from 35 minutes ago", t, func() {
		changeSum := kitepinger.ChangeSummary{
			OldStatus:    kitepinger.Failure,
			OldStatusDur: 35 * time.Minute,
		}
		fakeMount := &Mount{
			MountFolder: req.MountFolder{
				LocalPath: "fakeDir",
			},
		}
		mounter := Mounter{
			Log:     testutil.DiscardLogger,
			Machine: &machine.Machine{},
		}

		Convey("When the PathUnmounter fails", func() {
			mounter.PathUnmounter = func(string) error {
				return errors.New("Fake failure")
			}

			Convey("It should set the machine status to error", func() {
				err := mounter.handleChangeSummary(fakeMount, changeSum)
				So(err, ShouldNotBeNil)
				status, msg := mounter.Machine.GetStatus()
				So(status, ShouldEqual, machine.MachineError)
				So(msg, ShouldEqual, autoRemountFailed)
			})
		})

		// TODO: fuseMountFolder is difficult to mock currently, need to figure
		// out how to make that more sane to test, without causing real fuse mounts.
		Convey("When the fuseMountFolder fails", nil)
	})
}

func TestMounterRemoteDirExistsCheck(tt *testing.T) {
	Convey("Given remoteDirExistsCheck() is called", tt, func() {
		t := &fakeTransport{TripResponses: map[string]*dnode.Partial{}}
		m := &Mounter{Transport: t}

		Convey("When the remote dir exists", func() {
			p := &dnode.Partial{Raw: []byte(`{"stdout":"","stderr":"","exitStatus":0}`)}
			t.TripResponses["exec"] = p

			Convey("It should return no error", func() {
				So(m.remoteDirExistsCheck(), ShouldBeNil)
			})
		})

		Convey("When the remote dir does not exist", func() {
			p := &dnode.Partial{Raw: []byte(`{"stdout":"","stderr":"","exitStatus":1}`)}
			t.TripResponses["exec"] = p

			Convey("It should return an error", func() {
				So(m.remoteDirExistsCheck(), ShouldEqual, ErrRemotePathDoesNotExist)
			})
		})
	})
}
