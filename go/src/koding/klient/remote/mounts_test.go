package remote

import (
	"errors"
	"koding/klient/remote/machine"
	"koding/klient/remote/mount"
	"koding/klient/storage"
	"testing"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRestoreMounts(t *testing.T) {
	Convey("Given a Remote", t, func() {
		callCounts := map[string]int{}
		callOrder := []string{}

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
			// Set it to a default value, so we don't accidentally call real method
			mockedRestoreMount: func(m *mount.Mount) error {
				return errors.New("default error")
			},
		}

		Convey("With some machines associated to the mounts", func() {
			r.mounts = []*mount.Mount{
				&mount.Mount{IP: "foo"},
				&mount.Mount{IP: "bar"},
			}
			r.maxRestoreAttempts = 3
			kg.AddByUrl("http://foo/kite")
			kg.AddByUrl("http://bar/kite")
			kg.AddByUrl("http://baz/kite")

			Convey("It should set machines with mounts' status to remounting", func() {
				r.restoreMounts()
				m, err := r.machines.GetByIP("foo")
				So(err, ShouldBeNil)
				status, statusMsg := m.GetRawStatus()
				So(status, ShouldEqual, machine.MachineRemounting)
				So(statusMsg, ShouldEqual, autoRemounting)

				m, err = r.machines.GetByIP("bar")
				So(err, ShouldBeNil)
				status, statusMsg = m.GetRawStatus()
				So(status, ShouldEqual, machine.MachineRemounting)
				So(statusMsg, ShouldEqual, autoRemounting)
			})

			Convey("It should not set machines without mounts' status", func() {
				r.restoreMounts()

				m, err := r.machines.GetByIP("baz")
				So(err, ShouldBeNil)
				status, statusMsg := m.GetRawStatus()
				So(status, ShouldEqual, machine.MachineStatusUnknown)
				So(statusMsg, ShouldEqual, "")
			})
		})

		Convey("With a mount that succeeds", func() {
			r.mounts = []*mount.Mount{&mount.Mount{IP: "foo"}}
			r.maxRestoreAttempts = 5
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
			r.mounts = []*mount.Mount{
				&mount.Mount{IP: "foo"},
				&mount.Mount{IP: "bar"},
			}
			r.maxRestoreAttempts = 4
			r.mockedRestoreMount = func(m *mount.Mount) error {
				callCounts[m.IP]++
				callOrder = append(callOrder, m.IP)
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

			Convey("It should call in the expected order", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(callOrder, ShouldResemble, []string{
					"foo",
					"bar",
					"bar",
					"bar",
				})
			})
		})

		Convey("With a mount that eventually succeeds", func() {
			r.mounts = []*mount.Mount{
				&mount.Mount{IP: "foo"},
				&mount.Mount{IP: "bar"},
				&mount.Mount{IP: "baz"},
			}
			r.maxRestoreAttempts = 20 // more than we should need, given working code.
			r.mockedRestoreMount = func(m *mount.Mount) error {
				callCounts[m.IP]++
				callOrder = append(callOrder, m.IP)
				isErrMount := m.IP == "bar" || m.IP == "baz"
				if isErrMount && callCounts[m.IP] < 4 {
					return errors.New("Fake error")
				}
				return nil
			}

			Convey("It should stop after the mount succeeds", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(callCounts, ShouldResemble, map[string]int{
					"foo": 1,
					"bar": 4, // 4th attempt should have succeeded
					"baz": 4, // 4th attempt should have succeeded
				})
			})

			Convey("With a failure pause", func() {
				// Pause 10ms for each failure
				r.restoreFailuresPause = 10 * time.Millisecond

				Convey("It should pause between calls", func() {
					start := time.Now()
					So(r.restoreMounts(), ShouldBeNil)
					runDur := time.Since(start)

					// 10ms pauses for failures after the first one, 8 failures in total,
					// 6 that should pause.
					// Should almost take 60ms, plus some allowence for runtime.
					So(runDur, ShouldAlmostEqual, 60*time.Millisecond, 10*time.Millisecond)
				})
			})

			Convey("It should call in the expected order", func() {
				So(r.restoreMounts(), ShouldBeNil)
				So(callOrder, ShouldResemble, []string{
					"foo",
					"bar",
					"baz",
					"bar",
					"baz",
					"bar",
					"baz",
					"bar",
					"baz",
				})
			})
		})
	})
}
