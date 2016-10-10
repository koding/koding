package command

import (
	"koding/klient/kiteerrortypes"
	"os/exec"
	"testing"

	"github.com/koding/kite"
	. "github.com/smartystreets/goconvey/convey"
)

func TestNewOutput(t *testing.T) {
	Convey("Given a non-exitstatus error when running the process", t, func() {
		// A fake command that should not be found, thus failing to run entirely.
		cmd := exec.Command("newOutputFakeCommand")

		Convey("It should return a kite ProcessError", func() {
			_, err := NewOutput(cmd)
			So(err, ShouldNotBeNil)

			kiteErr, ok := err.(*kite.Error)
			So(ok, ShouldBeTrue)
			So(kiteErr.Type, ShouldEqual, kiteerrortypes.ProcessError)
		})
	})

	Convey("Given an exitstatus error when running the process", t, func() {
		cmd := exec.Command("bash", "-c", "exit 7")

		Convey("It should not return an error", func() {
			_, err := NewOutput(cmd)
			So(err, ShouldBeNil)
		})

		Convey("It should return the exit status", func() {
			output, err := NewOutput(cmd)
			So(err, ShouldBeNil)
			So(output.ExitStatus, ShouldEqual, 7)
		})
	})
}
