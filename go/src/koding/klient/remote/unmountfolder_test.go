package remote

import (
	"errors"
	"testing"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	"github.com/koding/klient/remote/req"
	"github.com/koding/klient/storage"
	"github.com/koding/logging"
	. "github.com/smartystreets/goconvey/convey"
)

// unmountMocker mocks a Mount.unmounter, keeping track of the number of calls
// and returning an error specified in the struct.
type unmountMocker struct {
	// Name is not used in the struct, but rather by callers, to easily keep
	// track of this mounts name.. purely convenience.
	Name  string
	Calls int
	Error error
}

func (um *unmountMocker) Unmount() error {
	um.Calls += 1
	return um.Error
}

func TestUnmountFolder(t *testing.T) {
	Convey("Given a Remote with no mounts", t, func() {
		r := Remote{
			log:    logging.NewLogger("testing"),
			mounts: Mounts{},
		}

		Convey("When requesting a mount name and no path", func() {
			Convey("It should return a no-mount-no-path error", func() {
				var unmountPathCalled bool
				r.unmountPath = func(p string) error {
					unmountPathCalled = true
					return nil
				}

				err := r.UnmountFolder(req.UnmountFolder{Name: "foo"})
				So(err, ShouldNotBeNil)
				So(unmountPathCalled, ShouldBeFalse)

				kErr, ok := err.(*kite.Error)
				So(ok, ShouldBeTrue)
				So(kErr.Type, ShouldEqual, mountNotFoundNoPath)
			})
		})
	})

	Convey("Given a Remote with mounts", t, func() {
		goodUnmountMocker := &unmountMocker{Name: "good mount"}
		badUnmountMocker := &unmountMocker{
			Name:  "bad mount",
			Error: errors.New("bad mount error"),
		}

		r := Remote{
			log:     logging.NewLogger("testing"),
			storage: storage.NewMemoryStorage(),
			mounts: Mounts{
				&Mount{
					MountName: goodUnmountMocker.Name,
					unmounter: goodUnmountMocker,
				},
				&Mount{
					MountName: badUnmountMocker.Name,
					unmounter: badUnmountMocker,
				},
			},
		}

		Convey("When called with a name that exists", func() {
			Convey("It should call the appropriate Unmounter", func() {
				err := r.UnmountFolder(req.UnmountFolder{Name: goodUnmountMocker.Name})
				So(err, ShouldBeNil)
				So(goodUnmountMocker.Calls, ShouldEqual, 1)
				So(badUnmountMocker.Calls, ShouldEqual, 0)
			})

			Convey("It should remove the mount from the Mounts slice", func() {
				err := r.UnmountFolder(req.UnmountFolder{Name: goodUnmountMocker.Name})
				So(err, ShouldBeNil)
				So(len(r.mounts), ShouldEqual, 1)
				// only the bad unmounter should be left
				So(r.mounts[0].MountName, ShouldEqual, badUnmountMocker.Name)
			})
		})

		Convey("When called with a mount that fails to unmount", func() {
			Convey("It should still remove the mount from the Mounts slice", func() {
				err := r.UnmountFolder(req.UnmountFolder{Name: badUnmountMocker.Name})
				So(err, ShouldNotBeNil)
				So(len(r.mounts), ShouldEqual, 1)
				// only the good unmounter should be left
				So(r.mounts[0].MountName, ShouldEqual, goodUnmountMocker.Name)
			})
		})
	})
}
