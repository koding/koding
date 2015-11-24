package main

import (
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestRunCommand(t *testing.T) {
	Convey("Given command", t, func() {
		Convey("Then it should run it on remote machine", func() {
			r := RunCommand{
				Transport: &fakeTransport{
					TripResponses: map[string]interface{}{"remote.exec": ExecRes{}},
				},
			}

			r.Run("machine", []string{"ls -alh"})
			//So(err, ShouldBeNil)
		})
	})
}
