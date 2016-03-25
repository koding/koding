package mount

import (
	"errors"
	"testing"
	"time"

	"koding/klient/remote/kitepinger"
	"koding/klient/remote/machine"
	"koding/klient/remote/req"
	"koding/klient/testutil"

	. "github.com/smartystreets/goconvey/convey"
)

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
