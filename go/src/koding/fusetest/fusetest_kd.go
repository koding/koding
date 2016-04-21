package fusetest

import (
	. "github.com/smartystreets/goconvey/convey"
	"koding/klient/remote/machine"
	"time"
)

func startRemoteKlient(f *Fusetest) error {
	// This will only work with some ubuntu/nix distros.
	_, err := f.Remote.ExecCmd("sudo", "service", "klient", "start")
	// Sleep to give klient a moment to start
	time.Sleep(10 * time.Second)
	return err
}

func stopRemoteKlient(f *Fusetest) error {
	// This will only work with some ubuntu/nix distros.
	_, err := f.Remote.ExecCmd("sudo", "service", "klient", "stop")
	// Sleep to give klient a moment to stop
	time.Sleep(10 * time.Second)
	return err
}

func (f *Fusetest) TestKDListMachineStatus() {
	kd := NewKD()
	opts := f.OriginalMountOpts

	f.setupConveyWithoutDir("KDListMachineStatus", func() {
		Convey("Given no mount", func() {
			Convey("With an online machine", func() {
				Convey("It should show online", func() {
					status, err := kd.GetMachineStatus(opts.Name)
					So(err, ShouldBeNil)
					So(status, ShouldEqual, machine.MachineOnline)
				})
			})

			Convey("With an offline machine", func() {
				So(stopRemoteKlient(f), ShouldBeNil)
				defer startRemoteKlient(f)

				Convey("It should show offline", func() {
					status, err := kd.GetMachineStatus(opts.Name)
					So(err, ShouldBeNil)
					So(status, ShouldEqual, machine.MachineOffline)
				})
			})
		})

		Convey("Given a mount", func() {
			err := kd.MountWithNoPrefetch(opts.Name, opts.RemotePath, opts.LocalPath)
			So(err, ShouldBeNil)
			defer kd.Unmount(opts.Name)

			Convey("With an online machine", func() {
				Convey("It should show connected", func() {
					status, err := kd.GetMachineStatus(opts.Name)
					So(err, ShouldBeNil)
					So(status, ShouldEqual, machine.MachineConnected)
				})
			})

			Convey("With an offline machine", func() {
				So(stopRemoteKlient(f), ShouldBeNil)
				defer startRemoteKlient(f)

				Convey("It should show disconnected", func() {
					status, err := kd.GetMachineStatus(opts.Name)
					So(err, ShouldBeNil)
					So(status, ShouldEqual, machine.MachineDisconnected)
				})
			})
		})
	})
}

// Triggered with -sudo-misc opt
func (f *Fusetest) TestKDRemount() {
	kd := NewKD()
	opts := f.OriginalMountOpts

	f.setupConveyWithoutDir("KDRemount", func() {
		Convey("Given there is a mount", func() {
			err := kd.MountWithNoPrefetch(opts.Name, opts.RemotePath, opts.LocalPath)
			So(err, ShouldBeNil)
			defer kd.Unmount(opts.Name)

			Convey("And the remote machine is off, and klient is restarted", func() {
				So(stopRemoteKlient(f), ShouldBeNil)
				// We start it in another test, but to be safe we also defer here, or
				// we may leave the remote without a klient.
				defer startRemoteKlient(f)
				kd.Restart()

				Convey("It should show Remounting", func() {
					status, err := kd.GetMachineStatus(opts.Name)
					So(err, ShouldBeNil)
					So(status, ShouldEqual, machine.MachineRemounting)
				})

				Convey("When the remote is started again", func() {
					So(startRemoteKlient(f), ShouldBeNil)
					// TODO: When startRemoteKlient is able to run faster, we will need
					// to pause here manually, to give local-klient time to reconnect
					// after the disconnect. Not long though.

					Convey("It should show Connected", func() {
						status, err := kd.GetMachineStatus(opts.Name)
						So(err, ShouldBeNil)
						So(status, ShouldEqual, machine.MachineConnected)
					})

					Convey("It should remount", func() {
						f.RunOperationTests()
					})
				})
			})
		})
	})
}
