package remote

import (
	"errors"
	"testing"

	"koding/klient/remote/mount"
	"koding/klient/remote/req"

	"koding/klient/remote/machine"
	"koding/klient/storage"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
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
		kg := newMockKiteGetter()
		r := Remote{
			log:         discardLogger,
			mounts:      mount.Mounts{},
			kitesGetter: kg,
			machines:    machine.NewMachines(discardLogger, storage.NewMemoryStorage()),
			localKite: &kite.Kite{
				Id: "test id",
				Config: &config.Config{
					Username: "test user",
				},
			},
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

		kg := newMockKiteGetter()
		store := storage.NewMemoryStorage()
		r := Remote{
			log:         logging.NewLogger("testing"),
			kitesGetter: kg,
			storage:     store,
			machines:    machine.NewMachines(discardLogger, store),
			mounts: mount.Mounts{
				&mount.Mount{
					MountName: goodUnmountMocker.Name,
					Unmounter: goodUnmountMocker,
				},
				&mount.Mount{
					MountName: badUnmountMocker.Name,
					Unmounter: badUnmountMocker,
				},
			},
			localKite: &kite.Kite{
				Id: "test id",
				Config: &config.Config{
					Username: "test user",
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
