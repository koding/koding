package remote

import (
	"errors"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/storage"
	"testing"
	"time"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRestoreMounts(t *testing.T) {
	Convey("Given a Remote", t, func() {
		kg := newMockKiteGetter()
		store := storage.NewMemoryStorage()
		r := &Remote{
			localKite: &kite.Kite{
				Id: "test id",
				Config: &config.Config{
					Username: "test user",
				},
			},
			kitesGetter:       kg,
			log:               discardLogger,
			machines:          machine.NewMachines(discardLogger, store),
			machinesCacheMax:  1 * time.Second,
			machineNamesCache: map[string]string{},
			storage:           store,
		}

		Convey("With a mount that succeeds", func() {
			callCounts := map[string]int{}
			r.mounts = []*mount.Mount{&mount.Mount{IP: "foo"}}
			r.maxRestoreRetries = defaultMaxRestoreRetries
			r.mockedRestoreMount = func(m *mount.Mount) error {
				callCounts[m.IP]++
				return nil
			}

			Convey("It should restore it only once", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(callCounts, ShouldResemble, map[string]int{"foo": 1})
			})

			Convey("It should not remove the mount from the internal mount slice", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(len(r.mounts), ShouldEqual, 1)
			})
		})

		Convey("With a mount that succeeds and another that fails", func() {
			callCounts := map[string]int{}
			r.mounts = []*mount.Mount{
				&mount.Mount{IP: "foo"},
				&mount.Mount{IP: "bar"},
			}
			r.maxRestoreRetries = 3
			r.mockedRestoreMount = func(m *mount.Mount) error {
				callCounts[m.IP]++
				if m.IP == "bar" {
					return errors.New("Fake error")
				}
				return nil
			}

			Convey("It should only attempt the successful mount once", func() {
				So(r.restoreMounts(), ShouldBeNil)
				calls, ok := callCounts["foo"]
				So(ok, ShouldBeTrue) // prevent panics
				So(calls, ShouldEqual, 1)
			})

			Convey("It should repeat attempts for the failure", func() {
				So(r.restoreMounts(), ShouldBeNil)
				calls, ok := callCounts["bar"]
				So(ok, ShouldBeTrue) // prevent panics
				So(calls, ShouldEqual, 3)
			})
		})

		Convey("With a mount that eventually succeeds", func() {
			callCounts := map[string]int{}
			r.mounts = []*mount.Mount{
				&mount.Mount{IP: "foo"},
				&mount.Mount{IP: "bar"},
			}
			r.maxRestoreRetries = 10 // more than we should need, given working code.
			r.mockedRestoreMount = func(m *mount.Mount) error {
				callCounts[m.IP]++
				if m.IP == "bar" && callCounts[m.IP] < 4 {
					return errors.New("Fake error")
				}
				return nil
			}

			Convey("It should stop after the mount succeeds", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(callCounts, ShouldResemble, map[string]int{
					"foo": 1,
					"bar": 4, // 4th attempt should have succeeded
				})
			})
		})
	})
}
